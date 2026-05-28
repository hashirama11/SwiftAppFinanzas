import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    var onSetBudget: (UUID, Int, Int) -> Void
    var onAddBudget: (Int, Int) -> Void

    @State private var viewModel: BudgetViewModel?
    @State private var monedaSeleccionada: String = "VES"
    @State private var tipoSeleccionado: String = "gasto"

    var body: some View {
        Group {
            if let vm = viewModel {
                budgetContent(vm: vm)
            } else {
                ZStack {
                    theme.colors.background.ignoresSafeArea()
                    ProgressView().tint(theme.colors.primary).scaleEffect(1.2)
                }
            }
        }
        .background(theme.colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .id(viewModel?.state.anhoSeleccionado.description ?? "")
        .task { await setupViewModel() }
        .onReceive(NotificationCenter.default.publisher(for: .transactionDidChange)) { _ in
            Task { await viewModel?.loadData() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .budgetDidChange)) { _ in
            Task { await viewModel?.loadData() }
        }
        .onChange(of: monedaSeleccionada) { _, new in viewModel?.cambiarMoneda(new) }
        .onChange(of: tipoSeleccionado) { _, new in viewModel?.cambiarTipo(new) }
        .onAppear {
            Task { await viewModel?.loadData() }
        }
    }

    @ViewBuilder
    private func budgetContent(vm: BudgetViewModel) -> some View {
        let presupuestadas = vm.state.categoriasConPresupuesto

        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 20) {
                    monthSelector(vm: vm)
                    tipoToggle
                    currencyToggle

                    if !vm.state.isLoading {
                        if presupuestadas.isEmpty {
                            emptyState(vm: vm)
                        } else {
                            summaryCard(vm: vm)
                            presupuestosList(items: presupuestadas, vm: vm)
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 80)
            }
            .scrollIndicators(.hidden)

            fabButton
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private func emptyState(vm: BudgetViewModel) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 56))
                .foregroundColor(theme.colors.primary.opacity(0.3))

            VStack(spacing: 8) {
                Text("Sin presupuestos")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.colors.textPrimary)

                Text("Define un presupuesto para tus categorías y haz seguimiento de tus gastos e ingresos mes a mes.")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                onAddBudget(vm.state.mesSeleccionado, vm.state.anhoSeleccionado)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Agregar presupuesto")
                        .font(theme.typography.bodyLarge.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: theme.shapes.large)
                        .fill(
                            LinearGradient(
                                colors: [theme.colors.primary, theme.colors.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
        .padding(.top, 40)
    }

    // MARK: - Month Selector

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

    // MARK: - Tipo Toggle

    private var tipoToggle: some View {
        HStack(spacing: 0) {
            ForEach(["gasto", "ingreso"], id: \.self) { tipo in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        tipoSeleccionado = tipo
                    }
                } label: {
                    Text(tipo == "gasto" ? "Gastos" : "Ingresos")
                        .font(theme.typography.bodyMedium)
                        .fontWeight(tipoSeleccionado == tipo ? .semibold : .regular)
                        .foregroundColor(tipoSeleccionado == tipo ? .white : theme.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: theme.shapes.medium)
                                .fill(tipoSeleccionado == tipo ? theme.colors.primary : .clear)
                        )
                }
            }
        }
        .padding(4)
        .background(theme.colors.surfaceSecondary)
        .cornerRadius(theme.shapes.medium)
    }

    // MARK: - Currency Toggle

    private var currencyToggle: some View {
        HStack(spacing: 0) {
            ForEach(["VES", "USD"], id: \.self) { moneda in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        monedaSeleccionada = moneda
                    }
                } label: {
                    Text(moneda == "VES" ? "Bs." : "$")
                        .font(theme.typography.bodyMedium)
                        .fontWeight(monedaSeleccionada == moneda ? .semibold : .regular)
                        .foregroundColor(monedaSeleccionada == moneda ? .white : theme.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: theme.shapes.medium)
                                .fill(monedaSeleccionada == moneda ? theme.colors.primary : .clear)
                        )
                }
            }
        }
        .padding(4)
        .background(theme.colors.surfaceSecondary)
        .cornerRadius(theme.shapes.medium)
    }

    // MARK: - Summary Card

    private func summaryCard(vm: BudgetViewModel) -> some View {
        BudgetSummaryCard(
            totalPresupuestado: vm.state.totalPresupuestado,
            totalGastado: vm.state.totalReal,
            monedaSimbolo: monedaSeleccionada == "VES" ? "Bs." : "$",
            porcentaje: vm.state.porcentajeGlobal
        )
    }

    // MARK: - Presupuestos List

    private func presupuestosList(items: [CategoriaPresupuestada], vm: BudgetViewModel) -> some View {
        LazyVStack(spacing: 10) {
            ForEach(items) { item in
                Button {
                    onSetBudget(item.categoria.id, vm.state.mesSeleccionado, vm.state.anhoSeleccionado)
                } label: {
                    presupuestoCard(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func presupuestoCard(item: CategoriaPresupuestada) -> some View {
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
                    Text("\(monedaSeleccionada == "VES" ? "Bs." : "$")\(Formatters.currency.string(from: NSNumber(value: item.gastoReal)) ?? "0,00")")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textPrimary)
                    Text("de \(monedaSeleccionada == "VES" ? "Bs." : "$")\(Formatters.currency.string(from: NSNumber(value: item.montoPresupuestado)) ?? "0,00")")
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
                        .fill(
                            LinearGradient(
                                colors: barColor(pct: item.porcentaje, excedido: item.estaExcedido),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(CGFloat(min(item.porcentaje, 1.0)) * geo.size.width, item.porcentaje > 0 ? 4 : 0), height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: item.porcentaje)
                }
            }
            .frame(height: 8)

            HStack(spacing: 4) {
                Image(systemName: item.estaExcedido ? "exclamationmark.triangle.fill" : "info.circle.fill")
                    .font(.system(size: 11))
                Text(item.estaExcedido
                    ? "Excedido por \(monedaSeleccionada == "VES" ? "Bs." : "$")\(Formatters.currency.string(from: NSNumber(value: abs(item.restante))) ?? "0,00")"
                    : "\(Int(round(item.porcentaje * 100)))% · \(monedaSeleccionada == "VES" ? "Bs." : "$")\(Formatters.currency.string(from: NSNumber(value: item.restante)) ?? "0,00") restante"
                )
                .font(theme.typography.labelSmall)
                .foregroundColor(item.estaExcedido ? theme.colors.accentRed : theme.colors.accentGreen)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary.opacity(0.3))
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

    private func barColor(pct: Double, excedido: Bool) -> [Color] {
        if excedido { return [theme.colors.accentRed, theme.colors.accentRed.opacity(0.7)] }
        if pct > 0.8 { return [.orange, .orange.opacity(0.7)] }
        return [theme.colors.accentGreen, theme.colors.accentGreen.opacity(0.7)]
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button {
            if let vm = viewModel {
                onAddBudget(vm.state.mesSeleccionado, vm.state.anhoSeleccionado)
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.colors.primary, theme.colors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: theme.colors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                )
        }
        .padding(.trailing, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Helpers

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

    private func setupViewModel() async {
        let repo = FinanzasRepositoryImpl(modelContext: modelContext)
        let vm = BudgetViewModel(repository: repo)
        await vm.loadData()
        viewModel = vm
    }
}
