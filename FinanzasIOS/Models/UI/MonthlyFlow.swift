import Foundation

struct MonthlyFlow: Identifiable, Hashable {
    var id: String { month }
    let month: String
    let ingresos: Double
    let gastos: Double
}
