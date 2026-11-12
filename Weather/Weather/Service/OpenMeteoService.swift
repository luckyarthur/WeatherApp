import Foundation
import os

struct OpenMeteoService: WeatherServiceProtocol {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Weather",
                                       category: "OpenMeteoService")

    private static let defaultSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        return URLSession(configuration: configuration)
    }()

    private let session: URLSession

    init(session: URLSession = OpenMeteoService.defaultSession) {
        self.session = session
    }

    // MARK: - Geocoding API

    //look up place info for the name typed
    func searchPlaces(named name: String) async throws -> [Place] {
        let response: GeocodingResponse = try await get(
            "https://geocoding-api.open-meteo.com/v1/search",
            query: [
                URLQueryItem(name: "name", value: name),
                URLQueryItem(name: "count", value: "10"),
                URLQueryItem(name: "language", value: "en"),
                URLQueryItem(name: "format", value: "json"),
            ]
        )
        return response.results ?? []
    }

    // MARK: - Forecast API

    //weather info from current day up to 7 days
    func fetchForecast(latitude: Double, longitude: Double) async throws -> WeatherForecast {
        try await get(
            "https://api.open-meteo.com/v1/forecast",
            query: [
                URLQueryItem(name: "latitude", value: String(latitude)),
                URLQueryItem(name: "longitude", value: String(longitude)),
                URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,weather_code,wind_speed_10m,is_day"),
                URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"),
                URLQueryItem(name: "forecast_days", value: "7"),
                URLQueryItem(name: "timezone", value: "auto"),
                URLQueryItem(name: "timeformat", value: "unixtime"),
            ]
        )
    }

    // MARK: - Shared request method

    private func get<T: Decodable>(_ urlString: String, query: [URLQueryItem]) async throws -> T {
        guard var components = URLComponents(string: urlString) else {
            throw WeatherServiceError.invalidURL
        }
        components.queryItems = query
        guard let url = components.url else {
            throw WeatherServiceError.invalidURL
        }

        // 1. Transport
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let error as URLError {
            throw Self.mapTransportError(error)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw WeatherServiceError.network(error.localizedDescription)
        }

        // 2. HTTP status
        guard let http = response as? HTTPURLResponse else {
            throw WeatherServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            Self.logger.error("HTTP \(http.statusCode) from \(url.host() ?? "?", privacy: .public)")
            if http.statusCode == 429 {
                throw WeatherServiceError.rateLimited
            }
            // client side error
            if (400..<500).contains(http.statusCode),
               let payload = try? JSONDecoder().decode(OpenMeteoErrorResponse.self, from: data) {
                throw WeatherServiceError.api(reason: payload.reason)
            }
            throw WeatherServiceError.badStatus(http.statusCode)
        }

        // 3. Decoding
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            return try decoder.decode(T.self, from: data)
        } catch {
            Self.logger.error("Decoding \(String(describing: T.self), privacy: .public) failed: \(String(describing: error), privacy: .public)")
            throw WeatherServiceError.invalidResponse
        }
    }

    private static func mapTransportError(_ error: URLError) -> Error {
        switch error.code {
        case .cancelled:
            CancellationError()
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            WeatherServiceError.offline
        case .timedOut:
            WeatherServiceError.timedOut
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .secureConnectionFailed:
            WeatherServiceError.serverUnreachable
        default:
            WeatherServiceError.network(error.localizedDescription)
        }
    }
}
