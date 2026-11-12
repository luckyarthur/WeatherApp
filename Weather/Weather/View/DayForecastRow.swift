import SwiftUI

struct DayForecastRow: View {
    let day: DayForecast
    let timeZone: TimeZone

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var dateWidth: CGFloat = 110
    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 30
    @ScaledMetric(relativeTo: .body) private var highWidth: CGFloat = 36

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            // very large text: the date gets its own line
            VStack(alignment: .leading, spacing: 4) {
                dateText
                HStack {
                    conditionAndChance
                    Spacer()
                    temperatures
                }
            }
        } else {
            HStack {
                dateText
                    .frame(width: dateWidth, alignment: .leading)
                conditionAndChance
                Spacer()
                temperatures
            }
        }
    }

    private var dateText: some View {
        Text(day.date.formatted(Date.FormatStyle(timeZone: timeZone).weekday(.abbreviated).day().month(.abbreviated)))
    }

    @ViewBuilder
    private var conditionAndChance: some View {
        Image(systemName: WeatherCondition(code: day.weatherCode).symbolName)
            .symbolRenderingMode(.multicolor)
            .frame(width: iconWidth)
        if let chance = day.precipitationProbability, chance > 0 {
            Text("\(chance)%")
                .font(.caption)
                .foregroundStyle(.blue)
        }
    }

    @ViewBuilder
    private var temperatures: some View {
        Text("\(day.low, specifier: "%.0f")°")
            .foregroundStyle(.secondary)
        Text("\(day.high, specifier: "%.0f")°")
            .frame(minWidth: highWidth, alignment: .trailing)
    }
}
