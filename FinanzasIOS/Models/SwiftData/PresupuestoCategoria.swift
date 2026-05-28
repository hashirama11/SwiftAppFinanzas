import Foundation
import SwiftData

@Model
final class PresupuestoCategoria {
    var id: UUID
    @Relationship(deleteRule: .nullify)
    var categoria: Categoria?
    var categoriaId: UUID?
    var mes: Int
    var anho: Int
    var monto: Double
    var moneda: String
    var esRecurrente: Bool = false

    var monedaEnum: Moneda {
        get { Moneda(rawValue: moneda) ?? .VES }
        set { moneda = newValue.rawValue }
    }

    init(
        categoria: Categoria?,
        mes: Int,
        anho: Int,
        monto: Double,
        moneda: Moneda = .VES,
        esRecurrente: Bool = false
    ) {
        self.id = UUID()
        self.categoria = categoria
        self.categoriaId = categoria?.id
        self.mes = mes
        self.anho = anho
        self.monto = monto
        self.moneda = moneda.rawValue
        self.esRecurrente = esRecurrente
    }
}
