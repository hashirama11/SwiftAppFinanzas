import Foundation

enum AppRoute: Hashable {
    case dashboard
    case balance
    case profile
    case notifications
    case addTransaction(transactionId: UUID? = nil)
    case transactionDetail(transactionId: UUID)
    case allTransactions
    case categoryManagement
}

enum AppTab: String, CaseIterable {
    case dashboard
    case balance
    case notifications
    case profile

    var title: String {
        switch self {
        case .dashboard: "Inicio"
        case .balance: "Balance"
        case .notifications: "Alertas"
        case .profile: "Perfil"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "house.fill"
        case .balance: "chart.bar.fill"
        case .notifications: "bell.fill"
        case .profile: "person.fill"
        }
    }
}
