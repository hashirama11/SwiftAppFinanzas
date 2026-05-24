import SwiftUI

struct EmptyState: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.fill")
                .font(.system(size: 40))
                .foregroundColor(theme.colors.textSecondary.opacity(0.4))

            Text("No hay transacciones")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)

            Text("Toca el botón + para añadir tu primer movimiento")
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
