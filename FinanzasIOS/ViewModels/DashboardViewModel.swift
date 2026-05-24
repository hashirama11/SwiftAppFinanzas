import Foundation
import Observation
import SwiftUI

@Observable
final class DashboardViewModel {
    var state = DashboardState()
    var errorMessage: String?

    private let repository: FinanzasRepository

    init(repository: FinanzasRepository) {
        self.repository = repository
    }

    func loadData() async {
        state.isLoading = true
        errorMessage = nil

        let transacciones: [Transaccion]
        let usuario: Usuario?

        do {
            transacciones = try await repository.getAllTransacciones()
            usuario = try await repository.getUsuario()
        } catch {
            state.isLoading = false
            errorMessage = "Error al cargar datos: \(error.localizedDescription)"
            return
        }

        guard let usuario else {
            state.isLoading = false
            return
        }

        let transactionsWithDetails: [TransactionWithDetails] = transacciones.map {
            TransactionWithDetails(transaccion: $0, categoria: $0.categoria)
        }

        let newState = await computeState(
            transactions: transactionsWithDetails,
            userName: usuario.nombre
        )

        state = newState
    }

    func refreshFromCache() async {
        let newState = await computeState(
            transactions: state.transactionsWithDetails,
            userName: state.userName
        )
        state = newState
    }
}

private func computeState(
    transactions: [TransactionWithDetails],
    userName: String
) async -> DashboardState {
    var totalIngresosVes: Double = 0
    var totalIngresosUsd: Double = 0
    var totalGastosVes: Double = 0
    var totalGastosUsd: Double = 0

    var ingresos: [TransactionWithDetails] = []
    var gastos: [TransactionWithDetails] = []

    for tx in transactions {
        let monto = tx.transaccion.monto
        switch tx.transaccion.tipoEnum {
        case .ingreso:
            ingresos.append(tx)
            if tx.transaccion.monedaEnum == .VES { totalIngresosVes += monto }
            else { totalIngresosUsd += monto }
        case .gasto:
            gastos.append(tx)
            if tx.transaccion.monedaEnum == .VES { totalGastosVes += monto }
            else { totalGastosUsd += monto }
        }
    }

    let incomeChartDataVes = buildChartData(from: ingresos, currency: .VES)
    let incomeChartDataUsd = buildChartData(from: ingresos, currency: .USD)
    let expenseChartDataVes = buildChartData(from: gastos, currency: .VES)
    let expenseChartDataUsd = buildChartData(from: gastos, currency: .USD)

    return DashboardState(
        transactionsWithDetails: transactions,
        totalIngresosVes: totalIngresosVes,
        totalIngresosUsd: totalIngresosUsd,
        totalGastosVes: totalGastosVes,
        totalGastosUsd: totalGastosUsd,
        isLoading: false,
        userName: userName,
        expenseChartDataVes: expenseChartDataVes,
        expenseChartDataUsd: expenseChartDataUsd,
        incomeChartDataVes: incomeChartDataVes,
        incomeChartDataUsd: incomeChartDataUsd
    )
}

private let chartColors: [Color] = [
    Color(red: 0 / 255, green: 137 / 255, blue: 123 / 255),
    Color(red: 77 / 255, green: 182 / 255, blue: 172 / 255),
    Color(red: 128 / 255, green: 203 / 255, blue: 196 / 255),
    Color(red: 178 / 255, green: 223 / 255, blue: 219 / 255),
    Color(red: 0 / 255, green: 77 / 255, blue: 64 / 255),
]

private func buildChartData(
    from transactions: [TransactionWithDetails],
    currency: Moneda
) -> [PieChartData] {
    let filtered = transactions.filter { $0.transaccion.monedaEnum == currency }
    guard !filtered.isEmpty else { return [] }

    let grouped = Dictionary(grouping: filtered) { tx in
        tx.categoria?.nombre ?? "Sin categoría"
    }

    var total: Double = 0
    var categoryTotals: [(name: String, total: Double)] = []

    for (name, txs) in grouped {
        let sum = txs.reduce(0.0) { $0 + $1.transaccion.monto }
        total += sum
        categoryTotals.append((name, sum))
    }

    guard total > 0 else { return [] }

    return categoryTotals.map { entry in
        let colorIndex = abs(entry.name.hashValue) % chartColors.count
        return PieChartData(
            value: entry.total / total,
            color: chartColors[colorIndex],
            categoryName: entry.name
        )
    }.sorted { $0.value > $1.value }
}
