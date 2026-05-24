import Foundation
import SwiftData

@Model
final class Transaccion {
    var id: UUID
    var monto: Double
    var moneda: String
    var descripcion: String
    var fecha: Date
    var tipo: String
    var estado: String
    var categoria: Categoria?
    var fechaConcrecion: Date?

    var tipoEnum: TipoTransaccion {
        get { TipoTransaccion(rawValue: tipo) ?? .gasto }
        set { tipo = newValue.rawValue }
    }

    var estadoEnum: EstadoTransaccion {
        get { EstadoTransaccion(rawValue: estado) ?? .concretado }
        set { estado = newValue.rawValue }
    }

    var monedaEnum: Moneda {
        get { Moneda(rawValue: moneda) ?? .VES }
        set { moneda = newValue.rawValue }
    }

    var isPending: Bool {
        estadoEnum == .pendiente
    }

    init(
        id: UUID = UUID(),
        monto: Double,
        moneda: Moneda = .VES,
        descripcion: String = "",
        fecha: Date = Date(),
        tipo: TipoTransaccion = .gasto,
        estado: EstadoTransaccion = .concretado,
        categoria: Categoria? = nil,
        fechaConcrecion: Date? = nil
    ) {
        self.id = id
        self.monto = monto
        self.moneda = moneda.rawValue
        self.descripcion = descripcion
        self.fecha = fecha
        self.tipo = tipo.rawValue
        self.estado = estado.rawValue
        self.categoria = categoria
        self.fechaConcrecion = fechaConcrecion
    }
}
