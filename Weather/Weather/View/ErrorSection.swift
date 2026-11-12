import SwiftUI

// error message with a "Try again" button when retrying can help
struct ErrorSection: View {
    let title: String
    let error: WeatherServiceError
    let retry: () async -> Void

    @State private var isRetrying = false

    var body: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: error == .offline ? "wifi.slash" : "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }

            if error.isRetryable {
                Button {
                    Task {
                        isRetrying = true
                        await retry()
                        isRetrying = false
                    }
                } label: {
                    HStack {
                        Text("Try again")
                        if isRetrying {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isRetrying)
            }
        }
    }
}
