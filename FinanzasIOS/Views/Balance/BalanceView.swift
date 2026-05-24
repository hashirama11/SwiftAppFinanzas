import SwiftUI
import SwiftData
import Charts

struct BalanceView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: BalanceViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                balanceContent(vm: vm)
            } else {
                loadingView
            }
        }
        .background(theme.colors.background)
        .task {
            await setupViewModel()
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .transactionDidChange) {
                await viewModel?.loadData()
            }
        }
    }

    @ViewBuilder
    private func balanceContent(vm: BalanceViewModel) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                netBalanceCards(vm: vm)
                savingsRateCard(vm: vm)
                monthlyChartSection(vm: vm)
                monthlyDetailSection(vm: vm)
            }
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Balance General")
                .font(theme.typography.headlineMedium)
                .foregroundColor(theme.colors.textPrimary)

            Text("Informe consolidado de tus finanzas")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private func netBalanceCards(vm: BalanceViewModel) -> some View {
        VStack(spacing: 12) {
            netBalanceRow(
                currency: .VES,
                ingresos: vm.state.totalIngresosVes,
                gastos: vm.state.totalGastosVes,
                balance: vm.state.balanceNetoVes
            )
            netBalanceRow(
                currency: .USD,
                ingresos: vm.state.totalIngresosUsd,
                gastos: vm.state.totalGastosUsd,
                balance: vm.state.balanceNetoUsd
            )
        }
        .padding(.horizontal, 20)
    }

    private func netBalanceRow(
        currency: Moneda,
        ingresos: Double,
        gastos: Double,
        balance: Double
    ) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(currency.nombre)
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.colors.primary)

                Spacer()

                Text(Formatters.formatCurrency(abs(balance), simbolo: currency.simbolo))
                    .font(theme.typography.titleLarge)
                    .foregroundColor(balance >= 0 ? theme.colors.accentGreen : theme.colors.accentRed)
            }

            HStack(spacing: 24) {
                flowItem(
                    label: "Ingresos",
                    amount: Formatters.formatCurrency(ingresos, simbolo: currency.simbolo),
                    color: theme.colors.accentGreen,
                    icon: "arrow.down.left"
                )
                flowItem(
                    label: "Gastos",
                    amount: Formatters.formatCurrency(gastos, simbolo: currency.simbolo),
                    color: theme.colors.accentRed,
                    icon: "arrow.up.right"
                )
                flowItem(
                    label: "Neto",
                    amount: "\(balance >= 0 ? "+" : "")\(Formatters.formatCurrency(balance, simbolo: currency.simbolo))",
                    color: balance >= 0 ? theme.colors.accentGreen : theme.colors.accentRed,
                    icon: balance >= 0 ? "arrow.up" : "arrow.down"
                )
            }
        }
        .padding(16)
        .cardBackground()
    }

    private func flowItem(label: String, amount: String, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)

            Text(amount)
                .font(theme.typography.labelMedium)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func savingsRateCard(vm: BalanceViewModel) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Tasa de Ahorro")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                Text(String(format: "%.1f%%", vm.state.tasaAhorro * 100))
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(savingsRateColor(vm.state.tasaAhorro))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.colors.surfaceSecondary)
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(savingsRateColor(vm.state.tasaAhorro))
                        .frame(width: max(12, geometry.size.width * vm.state.tasaAhorro), height: 12)
                        .animation(.easeInOut(duration: 0.8), value: vm.state.tasaAhorro)
                }
            }
            .frame(height: 12)

            HStack {
                Text("0%").font(theme.typography.labelSmall).foregroundColor(theme.colors.textSecondary)
                Spacer()
                Text("50%").font(theme.typography.labelSmall).foregroundColor(theme.colors.textSecondary)
                Spacer()
                Text("100%").font(theme.typography.labelSmall).foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(16)
        .cardBackground()
        .padding(.horizontal, 20)
    }

    private func savingsRateColor(_ rate: Double) -> Color {
        if rate < 0.1 { return theme.colors.accentRed }
        if rate < 0.3 { return .orange }
        return theme.colors.accentGreen
    }

    @State private var chartCurrency: Moneda = .VES

    private func monthlyChartSection(vm: BalanceViewModel) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Flujo Mensual")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                HStack(spacing: 12) {
                    legendDot(color: theme.colors.accentGreen, label: "Ingresos")
                    legendDot(color: theme.colors.accentRed, label: "Gastos")
                }
            }

            Picker("Moneda", selection: $chartCurrency) {
                Text("Bs.").tag(Moneda.VES)
                Text("USD").tag(Moneda.USD)
            }
            .pickerStyle(.segmented)
            .padding(.top, -4)

            if vm.state.monthlyFlows.isEmpty {
                emptyChartView
            } else {
                Chart(vm.state.monthlyFlows) { flow in
                    BarMark(
                        x: .value("Mes", flow.month),
                        y: .value("Ingresos", chartCurrency == .VES ? flow.ingresosVes : flow.ingresosUsd)
                    )
                    .foregroundStyle(theme.colors.accentGreen)
                    .cornerRadius(4)

                    BarMark(
                        x: .value("Mes", flow.month),
                        y: .value("Gastos", chartCurrency == .VES ? flow.gastosVes : flow.gastosUsd)
                    )
                    .foregroundStyle(theme.colors.accentRed)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
            }
        }
        .padding(16)
        .cardBackground()
        .padding(.horizontal, 20)
    }

    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 40))
                .foregroundColor(theme.colors.textSecondary.opacity(0.4))

            Text("Sin datos mensuales")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(height: 200)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.textSecondary)
        }
    }

    private func monthlyDetailSection(vm: BalanceViewModel) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Detalle Mensual")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(Array(vm.state.monthlyFlows.enumerated()), id: \.element.id) { index, flow in
                    monthlyDetailRow(flow: flow)

                    if index < vm.state.monthlyFlows.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.shapes.medium))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }

    private func monthlyDetailRow(flow: MonthlyFlow) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(flow.month)
                    .font(theme.typography.bodyLarge)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.primary)
                    .frame(width: 44, alignment: .leading)

                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            if flow.ingresos > 0 {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(theme.colors.accentGreen)
                                    .frame(width: ingresosBarWidth(total: geometry.size.width, flow: flow))
                            }
                            if flow.gastos > 0 {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(theme.colors.accentRed)
                                    .frame(width: gastosBarWidth(total: geometry.size.width, flow: flow))
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .frame(height: 6)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("+\(Formatters.currency.string(from: NSNumber(value: flow.ingresos)) ?? "0.00")")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.accentGreen)

                    Text("-\(Formatters.currency.string(from: NSNumber(value: flow.gastos)) ?? "0.00")")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.accentRed)
                }
            }

            HStack(spacing: 8) {
                Spacer()
                    .frame(width: 44)

                currencyDetailTag(
                    label: "Bs.",
                    ingresos: flow.ingresosVes,
                    gastos: flow.gastosVes
                )

                currencyDetailTag(
                    label: "USD",
                    ingresos: flow.ingresosUsd,
                    gastos: flow.gastosUsd
                )

                Spacer()
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }

    private func currencyDetailTag(label: String, ingresos: Double, gastos: Double) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(theme.colors.textSecondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(theme.colors.surfaceSecondary)
                .clipShape(Capsule())

            if ingresos > 0 {
                Text("+\(Formatters.formatCompact(ingresos))")
                    .font(.system(size: 9))
                    .foregroundColor(theme.colors.accentGreen)
            }

            if gastos > 0 {
                Text("-\(Formatters.formatCompact(gastos))")
                    .font(.system(size: 9))
                    .foregroundColor(theme.colors.accentRed)
            }
        }
    }

    private func ingresosBarWidth(total: CGFloat, flow: MonthlyFlow) -> CGFloat {
        let maxFlow = max(flow.ingresos, flow.gastos)
        guard maxFlow > 0 else { return 0 }
        return total * (flow.ingresos / maxFlow) * 0.48
    }

    private func gastosBarWidth(total: CGFloat, flow: MonthlyFlow) -> CGFloat {
        let maxFlow = max(flow.ingresos, flow.gastos)
        guard maxFlow > 0 else { return 0 }
        return total * (flow.gastos / maxFlow) * 0.48
    }

    private func setupViewModel() async {
        let repo = FinanzasRepositoryImpl(modelContext: modelContext)
        let vm = BalanceViewModel(repository: repo)
        await vm.loadData()
        viewModel = vm
    }

    private var loadingView: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .tint(theme.colors.primary)
                    .scaleEffect(1.2)
                Text("Cargando...")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
    }
}
