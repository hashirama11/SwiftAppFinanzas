import Foundation

enum Moneda: String, Codable, CaseIterable, Hashable {
    case VES = "VES"
    case USD = "USD"

    var simbolo: String {
        switch self {
        case .VES: "Bs."
        case .USD: "$"
        }
    }

    var nombre: String {
        switch self {
        case .VES: "Bolívares"
        case .USD: "Dólares"
        }
    }

    var codigoISO: String {
        rawValue
    }
}
