import Foundation
import Observation

@Observable
final class BalanceViewModel {
    var state = BalanceState()
    var errorMessage: String?

    private let repository: FinanzasRepository

    init(repository: FinanzasRepository) {
        self.repository = repository
    }

    func loadData() async {
        state.isLoading = true
        errorMessage = nil

        let transacciones: [Transaccion]
        do {
            transacciones = try await repository.getAllTransacciones()
        } catch {
            state.isLoading = false
            errorMessage = "Error al cargar datos: \(error.localizedDescription)"
            return
        }

        let newState = await computeState(from: transacciones)
        state = newState
    }
}

private func computeState(from transacciones: [Transaccion]) async -> BalanceState {
    var totalIngresosVes: Double = 0
    var totalIngresosUsd: Double = 0
    var totalGastosVes: Double = 0
    var totalGastosUsd: Double = 0

    let calendar = Calendar.current
    let now = Date()
    guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
        return BalanceState(isLoading: false)
    }

    var monthlyData: [(key: Date, ingresos: Double, gastos: Double)] = []
    for i in stride(from: 5, through: 0, by: -1) {
        if let targetMonth = calendar.date(byAdding: .month, value: -i, to: monthStart) {
            monthlyData.append((key: targetMonth, ingresos: 0, gastos: 0))
        }
    }

    for tx in transacciones {
        let monto = tx.monto
        switch tx.tipoEnum {
        case .ingreso:
            if tx.monedaEnum == .VES { totalIngresosVes += monto }
            else { totalIngresosUsd += monto }
        case .gasto:
            if tx.monedaEnum == .VES { totalGastosVes += monto }
            else { totalGastosUsd += monto }
        }

        let components = calendar.dateComponents([.year, .month], from: tx.fecha)
        guard let transDate = calendar.date(from: components) else { continue }
        if let index = monthlyData.firstIndex(where: { calendar.isDate($0.key, equalTo: transDate, toGranularity: .month) }) {
            if tx.tipoEnum == .ingreso {
                monthlyData[index].ingresos += monto
            } else {
                monthlyData[index].gastos += monto
            }
        }
    }

    let balanceNetoVes = totalIngresosVes - totalGastosVes
    let balanceNetoUsd = totalIngresosUsd - totalGastosUsd

    let totalIngresosConsolidado = totalIngresosVes + totalIngresosUsd
    let balanceNetoConsolidado = (totalIngresosVes + totalIngresosUsd) - (totalGastosVes + totalGastosUsd)
    let tasaAhorro: Double = totalIngresosConsolidado > 0
        ? max(0.0, min(1.0, balanceNetoConsolidado / totalIngresosConsolidado))
        : 0.0

    let monthlyFlows = monthlyData.map {
        MonthlyFlow(
            month: Formatters.formatMonth($0.key),
            ingresos: $0.ingresos,
            gastos: $0.gastos
        )
    }

    return BalanceState(
        totalIngresosVes: totalIngresosVes,
        totalIngresosUsd: totalIngresosUsd,
        totalGastosVes: totalGastosVes,
        totalGastosUsd: totalGastosUsd,
        balanceNetoVes: balanceNetoVes,
        balanceNetoUsd: balanceNetoUsd,
        tasaAhorro: tasaAhorro,
        monthlyFlows: monthlyFlows,
        isLoading: false
    )
}
