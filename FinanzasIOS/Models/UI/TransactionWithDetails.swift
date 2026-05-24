import Foundation

struct TransactionWithDetails: Identifiable, Hashable {
    let transaccion: Transaccion
    let categoria: Categoria?

    var id: UUID { transaccion.id }
}
