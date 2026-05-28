import SwiftUI

struct LoadingOverlay: View {
    @Environment(\.appTheme) private var theme

    let message: String

    init(_ message: String = "Cargando...") {
        self.message = message
    }

    var body: some View {
        ZStack {
            theme.colors.background.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .tint(theme.colors.primary)
                    .scaleEffect(1.3)

                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.colors.surface)
                    .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 4)
            )
        }
    }
}
