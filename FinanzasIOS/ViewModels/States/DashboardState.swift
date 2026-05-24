import Foundation

struct DashboardState {
    var transactionsWithDetails: [TransactionWithDetails] = []
    var totalIngresosVes: Double = 0.0
    var totalIngresosUsd: Double = 0.0
    var totalGastosVes: Double = 0.0
    var totalGastosUsd: Double = 0.0
    var isLoading: Bool = true
    var userName: String = ""
    var expenseChartDataVes: [PieChartData] = []
    var expenseChartDataUsd: [PieChartData] = []
    var incomeChartDataVes: [PieChartData] = []
    var incomeChartDataUsd: [PieChartData] = []
}
