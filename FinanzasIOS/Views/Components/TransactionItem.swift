import SwiftUI

struct TransactionItem: View {
    @Environment(\.appTheme) private var theme

    let transaction: TransactionWithDetails
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                iconView

                VStack(alignment: .leading, spacing: 3) {
                    Text(transaction.transaccion.descripcion)
                        .font(theme.typography.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if let categoria = transaction.categoria {
                            Text(categoria.nombre)
                                .font(theme.typography.labelSmall)
                                .foregroundColor(theme.colors.textSecondary)
                        }

                        if transaction.transaccion.isPending {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(theme.colors.accentRed)
                                    .frame(width: 6, height: 6)
                                Text("Pendiente")
                                    .font(theme.typography.labelSmall)
                                    .foregroundColor(theme.colors.accentRed)
                            }
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(amountString)
                        .font(theme.typography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(amountColor)

                    Text(Formatters.formatDateShort(transaction.transaccion.fecha))
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconView: some View {
        let categoria = transaction.categoria
        let iconName = categoria?.iconoEnum.sfSymbol ?? "questionmark.circle"
        let isIncome = transaction.transaccion.tipoEnum == .ingreso

        return Image(systemName: iconName)
            .font(.system(size: 16))
            .foregroundColor(isIncome ? theme.colors.accentGreen : theme.colors.accentRed)
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(
                        (isIncome ? theme.colors.accentGreen : theme.colors.accentRed)
                            .opacity(0.1)
                    )
            )
    }

    private var amountString: String {
        let prefix = transaction.transaccion.tipoEnum == .ingreso ? "+" : "-"
        let formatted = Formatters.currency.string(from: NSNumber(value: transaction.transaccion.monto))
            ?? String(format: "%.2f", transaction.transaccion.monto)
        return "\(prefix)\(transaction.transaccion.monedaEnum.simbolo) \(formatted)"
    }

    private var amountColor: Color {
        transaction.transaccion.tipoEnum == .ingreso
            ? theme.colors.accentGreen
            : theme.colors.accentRed
    }
}
