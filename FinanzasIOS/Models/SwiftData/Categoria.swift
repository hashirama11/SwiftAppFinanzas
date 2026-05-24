import Foundation
import SwiftData

@Model
final class Categoria {
    var id: UUID
    var nombre: String
    var icono: String
    var tipo: String
    var esPersonalizada: Bool

    @Relationship(deleteRule: .nullify, inverse: \Transaccion.categoria)
    var transacciones: [Transaccion]? = []

    var tipoEnum: TipoTransaccion {
        get { TipoTransaccion(rawValue: tipo) ?? .gasto }
        set { tipo = newValue.rawValue }
    }

    var iconoEnum: IconosEstandar {
        get { IconosEstandar(rawValue: icono) ?? .otros }
        set { icono = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        nombre: String,
        icono: IconosEstandar = .otros,
        tipo: TipoTransaccion = .gasto,
        esPersonalizada: Bool = false
    ) {
        self.id = id
        self.nombre = nombre
        self.icono = icono.rawValue
        self.tipo = tipo.rawValue
        self.esPersonalizada = esPersonalizada
    }
}
