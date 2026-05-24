import Foundation
import Observation

@Observable
final class AllTransactionsViewModel {
    var state = AllTransactionsState()

    private let repository: FinanzasRepository

    init(repository: FinanzasRepository) {
        self.repository = repository
    }

    func loadData() async {
        guard let transacciones = try? await repository.getAllTransacciones() else {
            state.isLoading = false
            return
        }

        let allTransactions: [TransactionWithDetails] = transacciones.map { transaccion in
            TransactionWithDetails(transaccion: transaccion, categoria: transaccion.categoria)
        }

        state.allTransactions = allTransactions
        applyFilters()
        state.isLoading = false
    }

    func onSearchQueryChange(_ query: String) {
        state.searchQuery = query
        applyFilters()
    }

    func onFilterTypeChange(_ type: TipoTransaccion?) {
        if state.filterType == type {
            state.filterType = nil
        } else {
            state.filterType = type
        }
        applyFilters()
    }

    func deleteTransaction(_ transaction: TransactionWithDetails) async {
        try? await repository.deleteTransaccion(by: transaction.transaccion.id)
        await MainActor.run {
            NotificationCenter.default.post(name: .transactionDidChange, object: nil)
        }
        await loadData()
    }

    private func applyFilters() {
        var filtered = state.allTransactions

        if !state.searchQuery.isEmpty {
            let query = state.searchQuery.lowercased()
            filtered = filtered.filter { tx in
                tx.transaccion.descripcion.lowercased().contains(query) ||
                (tx.categoria?.nombre.lowercased().contains(query) ?? false)
            }
        }

        if let filterType = state.filterType {
            filtered = filtered.filter { $0.transaccion.tipoEnum == filterType }
        }

        state.filteredTransactions = filtered
    }
}
