import Foundation

enum EstadoTransaccion: String, Codable, CaseIterable, Hashable {
    case concretado = "CONCRETADO"
    case pendiente = "PENDIENTE"

    var nombre: String {
        switch self {
        case .concretado: "Concretado"
        case .pendiente: "Pendiente"
        }
    }
}
