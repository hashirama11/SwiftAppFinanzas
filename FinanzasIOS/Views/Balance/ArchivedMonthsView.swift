import SwiftUI
import SwiftData

struct ArchivedMonthsView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    let onBack: () -> Void

    @State private var meses: [MesCerrado] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    theme.colors.background.ignoresSafeArea()
                    ProgressView().tint(theme.colors.primary).scaleEffect(1.2)
                }
            } else if meses.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Meses Anteriores")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .enableBackGesture()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.body.weight(.semibold))
                        Text("Atrás")
                    }
                    .foregroundColor(theme.colors.primary)
                }
            }
        }
        .task { await cargar() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.textSecondary.opacity(0.3))
            Text("Sin meses archivados")
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textSecondary)
            Text("Los meses anteriores se archivarán automáticamente al cambiar de mes.")
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 60)
    }

    private var listContent: some View {
        List {
            ForEach(meses) { mes in
                NavigationLink {
                    ArchivedMonthDetailView(mesCerrado: mes, onBack: {})
                } label: {
                    archivedMonthRow(mes)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func archivedMonthRow(_ mes: MesCerrado) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(nombreCompleto(mes: mes.mes, anho: mes.anho))
                    .font(theme.typography.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                Text(Formatters.formatDateShort(mes.fechaCierre))
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.colors.textSecondary)
            }

            HStack(spacing: 16) {
                balanceTag(
                    label: "Balance Bs.",
                    amount: mes.balanceVES,
                    simbolo: "Bs.",
                    isPositive: mes.balanceVES >= 0
                )
                balanceTag(
                    label: "Balance $",
                    amount: mes.balanceUSD,
                    simbolo: "$",
                    isPositive: mes.balanceUSD >= 0
                )
                Spacer()
                Text("\(mes.transaccionCount) trans.")
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.colors.textSecondary)
            }

            if !mes.presupuestosSnapshot.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 10))
                        .foregroundColor(theme.colors.primary)
                    Text("\(mes.presupuestosSnapshot.count) presupuestos")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.primary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func balanceTag(label: String, amount: Double, simbolo: String, isPositive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(theme.colors.textSecondary)
            Text("\(isPositive ? "+" : "")\(simbolo)\(Formatters.currency.string(from: NSNumber(value: abs(amount))) ?? "0,00")")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isPositive ? theme.colors.accentGreen : theme.colors.accentRed)
        }
    }

    private func nombreCompleto(mes: Int, anho: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        let index = mes - 1
        let mesNombre = (index >= 0 && index < formatter.monthSymbols.count)
            ? formatter.monthSymbols[index].capitalized
            : "Mes \(mes)"
        return "\(mesNombre) \(anho)"
    }

    private func cargar() async {
        let repo = FinanzasRepositoryImpl(modelContext: modelContext)
        if let result = try? await repo.getAllMesesCerrados() {
            meses = result
        }
        isLoading = false
    }
}

// MARK: - Archived Month Detail

private struct ArchivedMonthDetailView: View {
    @Environment(\.appTheme) private var theme

    let mesCerrado: MesCerrado
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryCard
                balanceCards
                presupuestosSection
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(theme.colors.background)
        .navigationTitle(nombreMes)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var nombreMes: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        let index = mesCerrado.mes - 1
        let mesNombre = (index >= 0 && index < formatter.monthSymbols.count)
            ? formatter.monthSymbols[index].capitalized
            : "Mes \(mesCerrado.mes)"
        return "\(mesNombre) \(mesCerrado.anho)"
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transacciones")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.textSecondary)
                    Text("\(mesCerrado.transaccionCount)")
                        .font(theme.typography.headlineMedium)
                        .foregroundColor(theme.colors.primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Tasa Ahorro")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.textSecondary)
                    Text(String(format: "%.1f%%", mesCerrado.tasaAhorro * 100))
                        .font(theme.typography.headlineMedium)
                        .foregroundColor(mesCerrado.tasaAhorro >= 0.3 ? theme.colors.accentGreen : .orange)
                }
            }
            Text("Archivado el \(Formatters.formatDate(mesCerrado.fechaCierre))")
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(16)
        .background(theme.colors.surface)
        .cornerRadius(theme.shapes.large)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var balanceCards: some View {
        VStack(spacing: 12) {
            balanceRow(currency: "Bs.", ingresos: mesCerrado.ingresosTotalesVES, gastos: mesCerrado.gastosTotalesVES)
            balanceRow(currency: "$", ingresos: mesCerrado.ingresosTotalesUSD, gastos: mesCerrado.gastosTotalesUSD)
        }
    }

    private func balanceRow(currency: String, ingresos: Double, gastos: Double) -> some View {
        HStack {
            Text(currency)
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.colors.primary)
                .frame(width: 30, alignment: .leading)
            Spacer()
            Text("+\(Formatters.currency.string(from: NSNumber(value: ingresos)) ?? "0,00")")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.accentGreen)
            Text("-\(Formatters.currency.string(from: NSNumber(value: gastos)) ?? "0,00")")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.accentRed)
        }
        .padding(12)
        .background(theme.colors.surface)
        .cornerRadius(theme.shapes.medium)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private var presupuestosSection: some View {
        let snapshot = mesCerrado.presupuestosSnapshot
        if !snapshot.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Presupuestos del mes")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.colors.textPrimary)
                ForEach(snapshot) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.categoriaIcono)
                            .font(.system(size: 14))
                            .foregroundColor(theme.colors.primary)
                            .frame(width: 28)
                        Text(item.categoriaNombre)
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(item.moneda == "VES" ? "Bs." : "$")\(Formatters.currency.string(from: NSNumber(value: item.gastoReal)) ?? "0,00")")
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textPrimary)
                            Text("de \(item.moneda == "VES" ? "Bs." : "$")\(Formatters.currency.string(from: NSNumber(value: item.montoPresupuestado)) ?? "0,00")")
                                .font(theme.typography.labelSmall)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    .padding(10)
                    .background(theme.colors.surfaceSecondary.opacity(0.5))
                    .cornerRadius(theme.shapes.small)
                }
            }
        }
    }
}
