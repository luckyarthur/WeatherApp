import Foundation

enum WeatherServiceError: LocalizedError, Equatable {
    
    case invalidURL
    case offline
    case timedOut
    case serverUnreachable
    case rateLimited
    case api(reason: String)
    case badStatus(Int)
    case invalidResponse
    case network(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Could not build the request."
        case .offline:
            "You appear to be offline. Check your connection and try again."
        case .timedOut:
            "The weather service took too long to respond. Try again."
        case .serverUnreachable:
            "Could not reach the weather service. Try again later."
        case .rateLimited:
            "Too many requests. Wait a minute and try again."
        case .api(let reason):
            "The weather service rejected the request: \(reason)"
        case .badStatus(let code):
            "The weather service returned an error (HTTP \(code))."
        case .invalidResponse:
            "The weather service sent an unexpected response."
        case .network(let message):
            message
        }
    }

    var isRetryable: Bool {
        switch self {
        case .invalidURL, .api:
            false
        case .offline, .timedOut, .serverUnreachable, .rateLimited, .badStatus, .invalidResponse, .network:
            true
        }
    }
}
