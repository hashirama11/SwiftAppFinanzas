import Foundation

enum TipoTransaccion: String, Codable, CaseIterable, Hashable {
    case ingreso = "INGRESO"
    case gasto = "GASTO"

    var nombre: String {
        switch self {
        case .ingreso: "Ingreso"
        case .gasto: "Gasto"
        }
    }
}
