import SwiftUI

struct BalanceCard: View {
    @Environment(\.appTheme) private var theme

    let vesAmount: Double
    let usdAmount: Double
    let isIncome: Bool

    private var title: String {
        isIncome ? "Total Ingresos" : "Total Gastos"
    }

    private var accentColor: Color {
        isIncome ? theme.colors.accentGreen : theme.colors.accentRed
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: isIncome ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(accentColor.opacity(0.12))
                    )

                Text(title)
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.colors.textSecondary)

                Spacer()
            }

            VStack(spacing: 6) {
                currencyRow(simbolo: Moneda.USD.simbolo, amount: usdAmount)
                currencyRow(simbolo: Moneda.VES.simbolo, amount: vesAmount)
            }
        }
        .padding(16)
        .cardBackground()
        .padding(.horizontal, 20)
    }

    private func currencyRow(simbolo: String, amount: Double) -> some View {
        HStack {
            Text(simbolo)
                .font(theme.typography.displayLarge)
                .foregroundColor(accentColor)

            Spacer()

            Text(Formatters.formatCurrency(amount, simbolo: ""))
                .font(theme.typography.displayLarge)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
        }
    }
}
