import Foundation

struct PendingNotification: Identifiable, Hashable {
    let id: String
    let transactionId: UUID?
    let titulo: String
    let descripcion: String
    let monto: Double
    let moneda: Moneda
    let tipo: TipoTransaccion
    let categoria: String?
    let fechaProgramada: Date
}
