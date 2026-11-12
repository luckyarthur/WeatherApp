import Foundation

// protocol to abstract the type
protocol WeatherServiceProtocol: Sendable {
    func searchPlaces(named name: String) async throws -> [Place]
    func fetchForecast(latitude: Double, longitude: Double) async throws -> WeatherForecast
}
