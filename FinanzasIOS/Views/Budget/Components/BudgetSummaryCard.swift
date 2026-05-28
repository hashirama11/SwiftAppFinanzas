import SwiftUI

struct BudgetSummaryCard: View {
    @Environment(\.appTheme) private var theme

    let totalPresupuestado: Double
    let totalGastado: Double
    let monedaSimbolo: String
    let porcentaje: Double

    var colorBarra: Color {
        if porcentaje > 1.0 { return theme.colors.accentRed }
        if porcentaje > 0.8 { return Color.orange }
        return theme.colors.accentGreen
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Presupuestado")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.textSecondary)
                    Text("\(monedaSimbolo)\(Formatters.currency.string(from: NSNumber(value: totalPresupuestado)) ?? "0,00")")
                        .font(theme.typography.titleLarge)
                        .foregroundColor(theme.colors.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Gastado")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.textSecondary)
                    Text("\(monedaSimbolo)\(Formatters.currency.string(from: NSNumber(value: totalGastado)) ?? "0,00")")
                        .font(theme.typography.titleLarge)
                        .foregroundColor(colorBarra)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.colors.surfaceSecondary)
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [colorBarra, colorBarra.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(CGFloat(min(porcentaje, 1.0)) * geometry.size.width, 0), height: 12)
                        .animation(.easeInOut(duration: 0.6), value: porcentaje)
                }
            }
            .frame(height: 12)

            HStack {
                let restante = totalPresupuestado - totalGastado
                if restante >= 0 {
                    Text("\(Int(round(porcentaje * 100)))% utilizado")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.textSecondary)
                } else {
                    Text("\(Int(round((porcentaje - 1.0) * 100)))% excedido")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.accentRed)
                }
                Spacer()
                Text("\(monedaSimbolo)\(Formatters.currency.string(from: NSNumber(value: abs(restante))) ?? "0,00") \(restante >= 0 ? "restante" : "excedido")")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(restante >= 0 ? theme.colors.accentGreen : theme.colors.accentRed)
            }
        }
        .padding(16)
        .background(theme.colors.surface)
        .cornerRadius(theme.shapes.large)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}
