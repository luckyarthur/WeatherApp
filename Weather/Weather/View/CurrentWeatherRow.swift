import SwiftUI

struct CurrentWeatherRow: View {
    let current: WeatherForecast.Current

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 48
    @ScaledMetric(relativeTo: .largeTitle) private var temperatureSize: CGFloat = 40

    var body: some View {
        let condition = WeatherCondition(code: current.weatherCode, isDay: current.isDay == 1)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: condition.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: iconSize))
                VStack(alignment: .leading) {
                    Text("\(current.temperature, specifier: "%.1f") °C")
                        .font(.system(size: temperatureSize, weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text(condition.description)
                        .foregroundStyle(.secondary)
                }
            }
            details
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var details: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) {
                feelsLike
                humidity
                wind
                rain
            }
        } else {
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 6) {
                GridRow {
                    feelsLike
                    humidity
                }
                GridRow {
                    wind
                    rain
                }
            }
        }
    }

    private var feelsLike: some View {
        Label("Feels like \(current.apparentTemperature, specifier: "%.1f") °C",
              systemImage: "thermometer.medium")
    }

    private var humidity: some View {
        Label("Humidity \(current.humidity)%", systemImage: "humidity")
    }

    private var wind: some View {
        Label("Wind \(current.windSpeed, specifier: "%.0f") km/h", systemImage: "wind")
    }

    private var rain: some View {
        Label("Rain \(current.precipitation, specifier: "%.1f") mm", systemImage: "drop")
    }
}
