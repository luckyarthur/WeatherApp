import Foundation
import Observation

@MainActor
@Observable
final class WeatherViewModel {
    enum SearchState: Equatable {
        //shorter than minimumQueryLength
        case idle
        case searching
        //finish check the position of the place, the array is empty when nothing matched
        // query is the text these places were searched with
        case loaded([Place], query: String)
        case failed(WeatherServiceError)
    }

    enum ForecastState: Equatable {
        // no place selected yet
        case idle
        case loading
        //the earlier data is kept with refreshError
        case loaded(WeatherForecast, refreshError: WeatherServiceError?)
        case failed(WeatherServiceError)
    }

    static let minimumQueryLength = 2

    //search text
    var query = ""

    private(set) var searchState: SearchState = .idle

    private(set) var selectedPlace: Place?
    // forecast of selectedPlace
    private(set) var forecastState: ForecastState = .idle

    private let service: WeatherServiceProtocol
    // Incremented per forecast request, to keep a record of current request
    private var forecastRequestID = 0

    init(service: WeatherServiceProtocol = OpenMeteoService()) {
        self.service = service
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // true, after showing places a new search typing starts
    var isRefiningSearch: Bool {
        if case .loaded(_, let searchedQuery) = searchState {
            return searchedQuery != trimmedQuery
        }
        return false
    }

    // MARK: - Place search

    // searches places for the current query
    func searchPlaces(debounce: Bool = true) async {
        let name = trimmedQuery
        guard name.count >= Self.minimumQueryLength else {
            searchState = .idle
            return
        }

        // update searchState
        if case .loaded = searchState {} else {
            searchState = .searching
        }

        do {
            if debounce {
                try await Task.sleep(for: .milliseconds(350))
            }
            let places = try await service.searchPlaces(named: name)
            // query may have changed while the request is on the way
            guard name == trimmedQuery else { return }
            searchState = .loaded(places, query: name)
        } catch is CancellationError {
            // handle the keystroke of changing query lead to cancel the previous task
        } catch {
            guard name == trimmedQuery else { return }
            searchState = .failed(Self.serviceError(from: error))
        }
    }

    // MARK: - Forecast

    // loads place weather
    func select(_ place: Place) async {
        selectedPlace = place
        // update state after new request comes
        forecastState = .loading
        query = ""
        searchState = .idle
        await loadForecast()
    }

    // request the forecast for the selected place
    func loadForecast() async {
        guard let place = selectedPlace else { return }

        //track the current request id
        forecastRequestID += 1
        let requestID = forecastRequestID
        // a refresh or retry state handle
        if forecastState == .idle {
            forecastState = .loading
        }

        do {
            let result = try await service.fetchForecast(latitude: place.latitude,
                                                         longitude: place.longitude)
            // check if the request is out of date
            guard requestID == forecastRequestID else { return }
            forecastState = .loaded(result, refreshError: nil)
        } catch is CancellationError {
            guard requestID == forecastRequestID else { return }
            //a cancelled load goes back to idle
            if forecastState == .loading {
                forecastState = .idle
            }
        } catch {
            guard requestID == forecastRequestID else { return }
            let serviceError = Self.serviceError(from: error)
            if case .loaded(let earlier, _) = forecastState {
                //keep the earlier data and report the error
                forecastState = .loaded(earlier, refreshError: serviceError)
            } else {
                forecastState = .failed(serviceError)
            }
        }
    }

    // MARK: - Helpers

    private static func serviceError(from error: Error) -> WeatherServiceError {
        (error as? WeatherServiceError) ?? .network(error.localizedDescription)
    }
}
