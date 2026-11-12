import Foundation

struct OpenMeteoErrorResponse: Decodable {
    let error: Bool
    let reason: String
}
