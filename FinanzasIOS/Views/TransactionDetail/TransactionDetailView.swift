import SwiftUI

struct TransactionDetailView: View {
    @Environment(\.appTheme) private var theme

    let transactionId: UUID
    let onBack: () -> Void
    let onEditClick: (UUID) -> Void

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.colors.primary, theme.colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 8) {
                    Text("Detalle")
                        .font(theme.typography.headlineMedium)
                        .foregroundColor(theme.colors.textPrimary)

                    Text("Información de la transacción")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                }

                HStack(spacing: 16) {
                    placeholderButton(
                        title: "Editar",
                        icon: "pencil",
                        action: { onEditClick(transactionId) }
                    )

                    placeholderButton(
                        title: "Eliminar",
                        icon: "trash",
                        isDestructive: true,
                        action: {}
                    )
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(theme.colors.primary)
                }
            }
        }
    }

    private func placeholderButton(
        title: String,
        icon: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(theme.typography.labelMedium)
                .foregroundColor(isDestructive ? theme.colors.accentRed : theme.colors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: theme.shapes.pill)
                        .fill(
                            isDestructive
                                ? theme.colors.accentRed.opacity(0.12)
                                : theme.colors.primary.opacity(0.12)
                        )
                )
        }
    }
}
