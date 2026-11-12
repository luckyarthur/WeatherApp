import Foundation

struct WeatherCondition {
    let description: String
    let symbolName: String

    init(code: Int, isDay: Bool = true) {
        switch code {
        case 0:
            description = "Clear sky"
            symbolName = isDay ? "sun.max" : "moon.stars"
        case 1:
            description = "Mainly clear"
            symbolName = isDay ? "sun.max" : "moon.stars"
        case 2:
            description = "Partly cloudy"
            symbolName = isDay ? "cloud.sun" : "cloud.moon"
        case 3:
            description = "Overcast"
            symbolName = "cloud"
        case 45, 48:
            description = "Fog"
            symbolName = "cloud.fog"
        case 51, 53, 55:
            description = "Drizzle"
            symbolName = "cloud.drizzle"
        case 56, 57:
            description = "Freezing drizzle"
            symbolName = "cloud.sleet"
        case 61, 63, 65:
            description = "Rain"
            symbolName = "cloud.rain"
        case 66, 67:
            description = "Freezing rain"
            symbolName = "cloud.sleet"
        case 71, 73, 75, 77:
            description = "Snow"
            symbolName = "cloud.snow"
        case 80, 81, 82:
            description = "Rain showers"
            symbolName = "cloud.heavyrain"
        case 85, 86:
            description = "Snow showers"
            symbolName = "cloud.snow"
        case 95:
            description = "Thunderstorm"
            symbolName = "cloud.bolt.rain"
        case 96, 99:
            description = "Thunderstorm with hail"
            symbolName = "cloud.bolt.rain"
        default:
            description = "Unknown"
            symbolName = "questionmark.circle"
        }
    }
}
