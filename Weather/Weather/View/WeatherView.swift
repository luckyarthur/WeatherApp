import SwiftUI

struct WeatherView: View {
    @State private var viewModel: WeatherViewModel
    @State private var isSearchPresented = false

    // the view model can be injected, a mock service for previews and tests
    @MainActor
    init(viewModel: WeatherViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? WeatherViewModel())
    }

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    searchResults
                } else if let place = viewModel.selectedPlace {
                    weatherSections(for: place)
                } else {
                    ContentUnavailableView(
                        "Search for a place",
                        systemImage: "magnifyingglass",
                        description: Text("Type a city or town name to see its weather.")
                    )
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Weather")
            .searchable(text: $viewModel.query,
                        isPresented: $isSearchPresented,
                        prompt: "City or place name")
            .autocorrectionDisabled()
            .task(id: viewModel.query) {
                await viewModel.searchPlaces()
            }
            .refreshable {
                //avoid re-render cancellation
                await Task { await viewModel.loadForecast() }.value
            }
        }
    }

    private var isSearching: Bool {
        !viewModel.trimmedQuery.isEmpty
    }

    // MARK: - Search results

    @ViewBuilder
    private var searchResults: some View {
        switch viewModel.searchState {
        case .idle:
            Section {
                Text("Type at least \(WeatherViewModel.minimumQueryLength) characters")
                    .foregroundStyle(.secondary)
            }
        case .searching:
            searchingRow
        case .loaded(let places, _) where places.isEmpty:
            // "No results" belongs to the older query, so show progress for the new one
            if viewModel.isRefiningSearch {
                searchingRow
            } else {
                ContentUnavailableView.search(text: viewModel.trimmedQuery)
                    .listRowBackground(Color.clear)
            }
        case .loaded(let places, _):
            Section {
                ForEach(places) { place in
                    Button {
                        isSearchPresented = false
                        Task { await viewModel.select(place) }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(place.name)
                                .foregroundStyle(.primary)
                            Text(place.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                // matches of the older query stay visible but can't be picked
                .disabled(viewModel.isRefiningSearch)
            } header: {
                HStack {
                    Text("Matches")
                    if viewModel.isRefiningSearch {
                        Spacer()
                        ProgressView()
                    }
                }
            }
        case .failed(let error):
            ErrorSection(title: "Search failed", error: error) {
                await viewModel.searchPlaces(debounce: false)
            }
        }
    }

    private var searchingRow: some View {
        Section {
            HStack {
                ProgressView()
                Text("Searching…")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Weather

    @ViewBuilder
    private func weatherSections(for place: Place) -> some View {
        switch viewModel.forecastState {
        case .idle:
            EmptyView()
        case .loading:
            Section(place.displayName) {
                HStack {
                    ProgressView()
                    Text("Loading weather…")
                        .foregroundStyle(.secondary)
                }
            }
        case .failed(let error):
            ErrorSection(title: "Couldn't load weather for \(place.name)", error: error) {
                await viewModel.loadForecast()
            }
        case .loaded(let forecast, let refreshError):
            if let refreshError {
                ErrorSection(title: "Couldn't refresh – showing earlier data", error: refreshError) {
                    await viewModel.loadForecast()
                }
            }
            Section(place.displayName) {
                CurrentWeatherRow(current: forecast.current)
            }
            Section("7-day forecast") {
                ForEach(forecast.days) { day in
                    DayForecastRow(day: day, timeZone: forecast.timeZone)
                }
            }
            Section {
                Link("Weather data by Open-Meteo.com",
                     destination: URL(string: "https://open-meteo.com/")!)
                    .font(.footnote)
            }
        }
    }
}
