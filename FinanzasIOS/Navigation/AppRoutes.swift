import Foundation

enum AppRoute: Hashable {
    case dashboard
    case balance
    case budget
    case profile
    case notifications
    case addTransaction(transactionId: UUID? = nil)
    case transactionDetail(transactionId: UUID)
    case allTransactions
    case categoryManagement
    case setBudget(categoriaId: UUID, mes: Int, anho: Int)
    case budgetCategoryPicker(mes: Int, anho: Int)
    case archivedMonths
}

enum AppTab: String, CaseIterable {
    case dashboard
    case balance
    case budget
    case profile

    var title: String {
        switch self {
        case .dashboard: "Inicio"
        case .balance: "Balance"
        case .budget: "Presupuesto"
        case .profile: "Perfil"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "house.fill"
        case .balance: "chart.bar.fill"
        case .budget: "chart.pie.fill"
        case .profile: "person.fill"
        }
    }
}
