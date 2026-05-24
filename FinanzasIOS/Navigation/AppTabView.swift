import SwiftUI

struct AppTabView: View {
    @Environment(\.appTheme) private var theme

    @State private var selectedTab: AppTab = .dashboard
    @State private var dashboardPath = NavigationPath()
    @State private var balancePath = NavigationPath()
    @State private var profilePath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            dashboardTab
            balanceTab
            profileTab
        }
        .tint(theme.colors.primary)
    }

    @ViewBuilder
    private var dashboardTab: some View {
        NavigationStack(path: $dashboardPath) {
            DashboardView(
                onAddTransaction: {
                    dashboardPath.append(AppRoute.addTransaction())
                },
                onTransactionClick: { transactionId in
                    dashboardPath.append(AppRoute.transactionDetail(transactionId: transactionId))
                },
                onSeeAllClick: {
                    dashboardPath.append(AppRoute.allTransactions)
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route, path: $dashboardPath)
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .tabItem {
            Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.systemImage)
        }
        .tag(AppTab.dashboard)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }

    @ViewBuilder
    private var balanceTab: some View {
        NavigationStack(path: $balancePath) {
            BalanceView()
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: AppRoute.self) { route in
                    destinationView(for: route, path: $balancePath)
                }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .tabItem {
            Label(AppTab.balance.title, systemImage: AppTab.balance.systemImage)
        }
        .tag(AppTab.balance)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }

    @ViewBuilder
    private var profileTab: some View {
        NavigationStack(path: $profilePath) {
            ProfileView(
                onCategoryManagementClick: {
                    profilePath.append(AppRoute.categoryManagement)
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route, path: $profilePath)
            }
        }
        .tabItem {
            Label(AppTab.profile.title, systemImage: AppTab.profile.systemImage)
        }
        .tag(AppTab.profile)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute, path: Binding<NavigationPath>) -> some View {
        switch route {
        case .addTransaction(let transactionId):
            AddTransactionView(
                transactionId: transactionId,
                onBack: { path.wrappedValue.removeLast() }
            )

        case .transactionDetail(let transactionId):
            TransactionDetailView(
                transactionId: transactionId,
                onBack: { path.wrappedValue.removeLast() },
                onEditClick: { id in
                    path.wrappedValue.append(AppRoute.addTransaction(transactionId: id))
                }
            )

        case .allTransactions:
            AllTransactionsView(
                onBack: { path.wrappedValue.removeLast() },
                onTransactionClick: { transactionId in
                    path.wrappedValue.append(AppRoute.transactionDetail(transactionId: transactionId))
                }
            )

        case .categoryManagement:
            CategoryManagementView(
                onBack: { path.wrappedValue.removeLast() }
            )

        case .dashboard, .balance, .profile:
            EmptyView()
        }
    }
}
