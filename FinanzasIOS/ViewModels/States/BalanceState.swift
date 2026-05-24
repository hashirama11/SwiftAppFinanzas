import Foundation

struct BalanceState {
    var totalIngresosVes: Double = 0.0
    var totalIngresosUsd: Double = 0.0
    var totalGastosVes: Double = 0.0
    var totalGastosUsd: Double = 0.0
    var balanceNetoVes: Double = 0.0
    var balanceNetoUsd: Double = 0.0
    var tasaAhorro: Double = 0.0
    var monthlyFlows: [MonthlyFlow] = []
    var isLoading: Bool = true
}
