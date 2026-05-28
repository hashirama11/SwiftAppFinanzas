import SwiftUI
import SwiftData
import Charts

private enum BalancePanel: String, CaseIterable {
    case general
    case presupuesto

    var title: String {
        switch self {
        case .general: "Balance General"
        case .presupuesto: "Presupuestos"
        }
    }
}

struct BalanceView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: BalanceViewModel?
    @State private var budgetVM: BudgetViewModel?
    @State private var selectedPanel: BalancePanel = .general
    var onArchivedMonths: (() -> Void)?

    var body: some View {
        Group {
            if viewModel != nil {
                balanceContent
            } else {
                loadingView
            }
        }
        .background(theme.colors.background)
        .task {
            await setupViewModels()
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .transactionDidChange) {
                await viewModel?.loadData()
                await budgetVM?.loadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .budgetDidChange)) { _ in
            Task {
                await budgetVM?.loadData()
            }
        }
    }

    @ViewBuilder
    private var balanceContent: some View {
        VStack(spacing: 0) {
            panelSelector

            if selectedPanel == .general, let vm = viewModel {
                generalBalanceView(vm: vm)
            } else if selectedPanel == .presupuesto, let bvm = budgetVM {
                presupuestoBalanceView(bvm: bvm)
            }
        }
    }

    // MARK: - Panel Selector

    private var panelSelector: some View {
        HStack(spacing: 0) {
            ForEach(BalancePanel.allCases, id: \.self) { panel in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedPanel = panel
                    }
                } label: {
                    Text(panel.title)
                        .font(theme.typography.bodyMedium)
                        .fontWeight(selectedPanel == panel ? .semibold : .regular)
                        .foregroundColor(selectedPanel == panel ? .white : theme.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: theme.shapes.medium)
                                .fill(selectedPanel == panel ? theme.colors.primary : .clear)
                        )
                }
            }
        }
        .padding(4)
        .background(theme.colors.surfaceSecondary)
        .cornerRadius(theme.shapes.medium)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    // MARK: - General Balance View

    @ViewBuilder
    private func generalBalanceView(vm: BalanceViewModel) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                netBalanceCards(vm: vm)
                savingsRateCard(vm: vm)
                monthlyChartSection(vm: vm)
                monthlyDetailSection(vm: vm)
                archivedMonthsButton
            }
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Presupuesto Balance View

    @ViewBuilder
    private func presupuestoBalanceView(bvm: BudgetViewModel) -> some View {
        let presupuestadas = bvm.state.categoriasConPresupuesto

        ScrollView {
            VStack(spacing: 20) {
                monthSelector(vm: bvm)
                tipoToggle(bvm: bvm)
                currencyToggle(bvm: bvm)

                if bvm.state.isLoading {
                    ProgressView().tint(theme.colors.primary).scaleEffect(1.2).padding(.top, 40)
                } else if presupuestadas.isEmpty {
                    emptyPresupuestoState
                } else {
                    presupuestoSummaryCard(bvm: bvm)
                    presupuestoList(items: presupuestadas, bvm: bvm)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Shared Components

    private var emptyPresupuestoState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.textSecondary.opacity(0.3))
            Text("Sin presupuestos este mes")
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textSecondary)
            Text("Ve a la pestaña Presupuesto para definir tus metas")
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    private func monthSelector(vm: BudgetViewModel) -> some View {
        HStack(spacing: 12) {
            Button {
                cambiarMes(vm: vm, delta: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(theme.colors.primary)
                    .frame(width: 36, height: 36)
                    .background(theme.colors.surface)
                    .cornerRadius(theme.shapes.small)
            }
            Spacer()
            Text("\(vm.state.mesNombre) \(String(vm.state.anhoSeleccionado))")
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            Button {
                cambiarMes(vm: vm, delta: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(theme.colors.primary)
                    .frame(width: 36, height: 36)
                    .background(theme.colors.surface)
                    .cornerRadius(theme.shapes.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(theme.colors.surface)
        .cornerRadius(theme.shapes.large)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private func tipoToggle(bvm: BudgetViewModel) -> some View {
        HStack(spacing: 0) {
            ForEach(["gasto", "ingreso"], id: \.self) { tipo in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        bvm.cambiarTipo(tipo)
                    }
                } label: {
                    Text(tipo == "gasto" ? "Gastos" : "Ingresos")
                        .font(theme.typography.bodyMedium)
                        .fontWeight(bvm.state.tipoFiltro == tipo ? .semibold : .regular)
                        .foregroundColor(bvm.state.tipoFiltro == tipo ? .white : theme.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: theme.shapes.medium)
                                .fill(bvm.state.tipoFiltro == tipo ? theme.colors.primary : .clear)
                        )
                }
            }
        }
        .padding(4)
        .background(theme.colors.surfaceSecondary)
        .cornerRadius(theme.shapes.medium)
    }

    private func currencyToggle(bvm: BudgetViewModel) -> some View {
        HStack(spacing: 0) {
            ForEach(["VES", "USD"], id: \.self) { moneda in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        bvm.cambiarMoneda(moneda)
                    }
                } label: {
                    Text(moneda == "VES" ? "Bs." : "$")
                        .font(theme.typography.bodyMedium)
                        .fontWeight(bvm.state.monedaFiltro == moneda ? .semibold : .regular)
                        .foregroundColor(bvm.state.monedaFiltro == moneda ? .white : theme.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: theme.shapes.medium)
                                .fill(bvm.state.monedaFiltro == moneda ? theme.colors.primary : .clear)
                        )
                }
            }
        }
        .padding(4)
        .background(theme.colors.surfaceSecondary)
        .cornerRadius(theme.shapes.medium)
    }

    private func presupuestoSummaryCard(bvm: BudgetViewModel) -> some View {
        BudgetSummaryCard(
            totalPresupuestado: bvm.state.totalPresupuestado,
            totalGastado: bvm.state.totalReal,
            monedaSimbolo: bvm.state.monedaFiltro == "VES" ? "Bs." : "$",
            porcentaje: bvm.state.porcentajeGlobal
        )
    }

    private func presupuestoList(items: [CategoriaPresupuestada], bvm: BudgetViewModel) -> some View {
        LazyVStack(spacing: 10) {
            ForEach(items) { item in
                presupuestoCard(item: item, bvm: bvm)
            }
        }
    }

    @ViewBuilder
    private func presupuestoCard(item: CategoriaPresupuestada, bvm: BudgetViewModel) -> some View {
        let simbolo = bvm.state.monedaFiltro == "VES" ? "Bs." : "$"

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: item.categoria.iconoEnum.sfSymbol)
                    .font(.system(size: 16))
                    .foregroundColor(item.categoria.tipoEnum == .ingreso ? theme.colors.accentGreen : theme.colors.accentRed)
                    .frame(width: 30)

                Text(item.categoria.nombre)
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(1)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(simbolo)\(Formatters.currency.string(from: NSNumber(value: item.gastoReal)) ?? "0,00")")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textPrimary)
                    Text("de \(simbolo)\(Formatters.currency.string(from: NSNumber(value: item.montoPresupuestado)) ?? "0,00")")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.colors.surfaceSecondary)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(pct: item.porcentaje, excedido: item.estaExcedido))
                        .frame(width: max(CGFloat(min(item.porcentaje, 1.0)) * geo.size.width, item.porcentaje > 0 ? 4 : 0), height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: item.porcentaje)
                }
            }
            .frame(height: 8)

            HStack(spacing: 4) {
                Image(systemName: item.estaExcedido ? "exclamationmark.triangle.fill" : "info.circle.fill")
                    .font(.system(size: 11))
                Text(item.estaExcedido
                    ? "Excedido por \(simbolo)\(Formatters.currency.string(from: NSNumber(value: abs(item.restante))) ?? "0,00")"
                    : "\(Int(round(item.porcentaje * 100)))% · \(simbolo)\(Formatters.currency.string(from: NSNumber(value: item.restante)) ?? "0,00") restante"
                )
                .font(theme.typography.labelSmall)
                .foregroundColor(item.estaExcedido ? theme.colors.accentRed : theme.colors.accentGreen)
                Spacer()
            }
        }
        .padding(14)
        .background(theme.colors.surface)
        .cornerRadius(theme.shapes.medium)
        .overlay(
            RoundedRectangle(cornerRadius: theme.shapes.medium)
                .stroke(item.estaExcedido ? theme.colors.accentRed.opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private func barColor(pct: Double, excedido: Bool) -> Color {
        if excedido { return theme.colors.accentRed }
        if pct > 0.8 { return .orange }
        return theme.colors.accentGreen
    }

    private func cambiarMes(vm: BudgetViewModel, delta: Int) {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = vm.state.anhoSeleccionado
        components.month = vm.state.mesSeleccionado
        components.day = 1
        guard let date = calendar.date(from: components),
              let newDate = calendar.date(byAdding: .month, value: delta, to: date) else { return }
        let newMonth = calendar.component(.month, from: newDate)
        let newYear = calendar.component(.year, from: newDate)
        vm.cambiarMes(a: newMonth, anho: newYear)
    }

    // MARK: - General Balance Sections

    private var archivedMonthsButton: some View {
        Button {
            onArchivedMonths?()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 16))
                    .foregroundColor(theme.colors.primary)
                Text("Meses Anteriores")
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(16)
            .background(theme.colors.surface)
            .cornerRadius(theme.shapes.medium)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
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

    // MARK: - Setup & Loading

    private func setupViewModels() async {
        let repo = FinanzasRepositoryImpl(modelContext: modelContext)

        let bvm = BalanceViewModel(repository: repo)
        await bvm.loadData()
        viewModel = bvm

        let budgetVMInstance = BudgetViewModel(repository: repo)
        await budgetVMInstance.loadData()
        budgetVM = budgetVMInstance
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
