import Foundation
import Observation

@Observable
final class TransactionDetailViewModel {
    var transactionWithDetails: TransactionWithDetails? = nil
    var isLoading: Bool = true

    private let repository: FinanzasRepository
    private let transactionId: UUID

    init(repository: FinanzasRepository, transactionId: UUID) {
        self.repository = repository
        self.transactionId = transactionId
    }

    func loadTransaction() async {
        isLoading = true

        guard let transaccion = try? await repository.getTransaccion(by: transactionId) else {
            isLoading = false
            return
        }

        let categoria = transaccion.categoria
        transactionWithDetails = TransactionWithDetails(transaccion: transaccion, categoria: categoria)
        isLoading = false
    }

    func deleteTransaction() async {
        try? await repository.deleteTransaccion(by: transactionId)
        await MainActor.run {
            NotificationCenter.default.post(name: .transactionDidChange, object: nil)
        }
    }
}
