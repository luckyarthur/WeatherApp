import Foundation

struct WeatherForecast: Decodable, Equatable {
    let timezone: String
    let current: Current
    let daily: Daily

    struct Current: Decodable, Equatable {
        let time: Date
        let temperature: Double        // °C
        let apparentTemperature: Double // °C
        let humidity: Int              // %
        let precipitation: Double      // mm
        let weatherCode: Int           // WMO code
        let windSpeed: Double          // km/h
        let isDay: Int                 // 1 = day, 0 = night

        enum CodingKeys: String, CodingKey {
            case time, precipitation
            case temperature = "temperature_2m"
            case apparentTemperature = "apparent_temperature"
            case humidity = "relative_humidity_2m"
            case weatherCode = "weather_code"
            case windSpeed = "wind_speed_10m"
            case isDay = "is_day"
        }
    }

    struct Daily: Decodable, Equatable {
        let time: [Date]
        let weatherCode: [Int]
        let temperatureMax: [Double]
        let temperatureMin: [Double]
        let precipitationProbabilityMax: [Int?]

        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case temperatureMax = "temperature_2m_max"
            case temperatureMin = "temperature_2m_min"
            case precipitationProbabilityMax = "precipitation_probability_max"
        }
    }
}

struct DayForecast: Identifiable {
    let date: Date
    let weatherCode: Int
    let high: Double
    let low: Double
    let precipitationProbability: Int?

    var id: Date { date }
}

extension WeatherForecast {
    var timeZone: TimeZone {
        TimeZone(identifier: timezone) ?? .current
    }

    var days: [DayForecast] {
        let count = min(daily.time.count,
                        daily.weatherCode.count,
                        daily.temperatureMax.count,
                        daily.temperatureMin.count)
        return (0..<count).map { index in
            DayForecast(
                date: daily.time[index],
                weatherCode: daily.weatherCode[index],
                high: daily.temperatureMax[index],
                low: daily.temperatureMin[index],
                precipitationProbability: index < daily.precipitationProbabilityMax.count
                    ? daily.precipitationProbabilityMax[index]
                    : nil
            )
        }
    }
}
