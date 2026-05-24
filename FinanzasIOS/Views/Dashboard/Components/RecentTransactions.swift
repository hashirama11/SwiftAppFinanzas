import SwiftUI

struct RecentTransactions: View {
    @Environment(\.appTheme) private var theme

    let transactions: [TransactionWithDetails]
    let onTransactionClick: (UUID) -> Void
    let onSeeAllClick: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Movimientos Recientes")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                Button(action: onSeeAllClick) {
                    Text("Ver Todas")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            if transactions.isEmpty {
                EmptyState()
            } else {
                VStack(spacing: 0) {
                    ForEach(transactions.prefix(5)) { tx in
                        TransactionItem(transaction: tx) {
                            onTransactionClick(tx.transaccion.id)
                        }

                        if tx.id != transactions.prefix(5).last?.id {
                            Divider()
                                .padding(.leading, 70)
                        }
                    }
                }
                .background(theme.colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: theme.shapes.medium))
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 20)
            }
        }
    }
}
