import Foundation
import Observation

@Observable
final class AllTransactionsViewModel {
    var state = AllTransactionsState()

    private let repository: FinanzasRepository

    init(repository: FinanzasRepository) {
        self.repository = repository
    }

    func loadInitialData() async {
        state.isLoading = true
        state.currentOffset = 0
        state.hasMorePages = true

        let tipoStr: String? = state.filterType?.rawValue
        let filtro: String? = state.searchQuery.isEmpty ? nil : state.searchQuery

        do {
            let transacciones = try await repository.getTransaccionesPaginadas(
                limit: state.pageSize,
                offset: 0,
                tipo: tipoStr,
                filtroTexto: filtro
            )
            let count = try await repository.getTransaccionesCount(tipo: tipoStr)

            state.transactions = transacciones.map {
                TransactionWithDetails(transaccion: $0, categoria: $0.categoria)
            }
            state.totalCount = count
            state.currentOffset = transacciones.count
            state.hasMorePages = transacciones.count < count
        } catch {
            state.transactions = []
            state.totalCount = 0
            state.hasMorePages = false
        }

        state.isLoading = false
    }

    func loadMore() async {
        guard !state.isLoadingMore, state.hasMorePages else { return }
        state.isLoadingMore = true

        let tipoStr: String? = state.filterType?.rawValue
        let filtro: String? = state.searchQuery.isEmpty ? nil : state.searchQuery

        do {
            let more = try await repository.getTransaccionesPaginadas(
                limit: state.pageSize,
                offset: state.currentOffset,
                tipo: tipoStr,
                filtroTexto: filtro
            )

            let nuevos = more.map {
                TransactionWithDetails(transaccion: $0, categoria: $0.categoria)
            }
            state.transactions.append(contentsOf: nuevos)
            state.currentOffset += more.count
            state.hasMorePages = state.currentOffset < state.totalCount
        } catch {}

        state.isLoadingMore = false
    }

    func onSearchQueryChange(_ query: String) {
        state.searchQuery = query
        Task { await loadInitialData() }
    }

    func onFilterTypeChange(_ type: TipoTransaccion?) {
        state.filterType = (state.filterType == type) ? nil : type
        Task { await loadInitialData() }
    }

    func deleteTransaction(_ transaction: TransactionWithDetails) async {
        try? await repository.deleteTransaccion(by: transaction.transaccion.id)
        await MainActor.run {
            NotificationCenter.default.post(name: .transactionDidChange, object: nil)
        }
        await loadInitialData()
    }
}
