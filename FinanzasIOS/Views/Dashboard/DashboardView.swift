import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    let onAddTransaction: () -> Void
    let onTransactionClick: (UUID) -> Void
    let onSeeAllClick: () -> Void

    @State private var viewModel: DashboardViewModel?
    @State private var selectedTab: Int = 0

    var body: some View {
        Group {
            if let vm = viewModel {
                dashboardContent(vm: vm)
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
    private func dashboardContent(vm: DashboardViewModel) -> some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                DashboardTopAppBar(userName: vm.state.userName)
                    .padding(.bottom, 12)

                DashboardTabRow(selectedTab: $selectedTab)
                    .padding(.bottom, 16)

                TabView(selection: $selectedTab) {
                    DashboardContent(
                        balanceAmountVes: vm.state.totalIngresosVes,
                        balanceAmountUsd: vm.state.totalIngresosUsd,
                        chartDataVes: vm.state.incomeChartDataVes,
                        chartDataUsd: vm.state.incomeChartDataUsd,
                        transactions: incomeTransactions(vm.state),
                        isIncome: true,
                        onTransactionClick: onTransactionClick,
                        onSeeAllClick: onSeeAllClick
                    )
                    .tag(0)

                    DashboardContent(
                        balanceAmountVes: vm.state.totalGastosVes,
                        balanceAmountUsd: vm.state.totalGastosUsd,
                        chartDataVes: vm.state.expenseChartDataVes,
                        chartDataUsd: vm.state.expenseChartDataUsd,
                        transactions: expenseTransactions(vm.state),
                        isIncome: false,
                        onTransactionClick: onTransactionClick,
                        onSeeAllClick: onSeeAllClick
                    )
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)
            }

            fabButton
        }
    }

    private var fabButton: some View {
        Button(action: onAddTransaction) {
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
                        .shadow(
                            color: theme.colors.primary.opacity(0.4),
                            radius: 12, x: 0, y: 6
                        )
                )
        }
        .padding(.trailing, 20)
        .padding(.bottom, 16)
        .ignoresSafeArea(.keyboard)
    }

    private func incomeTransactions(_ state: DashboardState) -> [TransactionWithDetails] {
        state.transactionsWithDetails.filter { $0.transaccion.tipoEnum == .ingreso }
    }

    private func expenseTransactions(_ state: DashboardState) -> [TransactionWithDetails] {
        state.transactionsWithDetails.filter { $0.transaccion.tipoEnum == .gasto }
    }

    private func setupViewModel() async {
        let repo = FinanzasRepositoryImpl(modelContext: modelContext)
        let vm = DashboardViewModel(repository: repo)
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

private struct DashboardContent: View {
    @Environment(\.appTheme) private var theme

    let balanceAmountVes: Double
    let balanceAmountUsd: Double
    let chartDataVes: [PieChartData]
    let chartDataUsd: [PieChartData]
    let transactions: [TransactionWithDetails]
    let isIncome: Bool
    let onTransactionClick: (UUID) -> Void
    let onSeeAllClick: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BalanceCard(
                    vesAmount: balanceAmountVes,
                    usdAmount: balanceAmountUsd,
                    isIncome: isIncome
                )

                PieChartView(
                    dataVes: chartDataVes,
                    dataUsd: chartDataUsd,
                    isIncome: isIncome
                )

                RecentTransactions(
                    transactions: transactions,
                    onTransactionClick: onTransactionClick,
                    onSeeAllClick: onSeeAllClick
                )
            }
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}
