import Foundation

enum TemaApp: String, Codable, CaseIterable, Hashable {
    case claro = "CLARO"
    case oscuro = "OSCURO"

    var nombre: String {
        switch self {
        case .claro: "Claro"
        case .oscuro: "Oscuro"
        }
    }
}
