import Foundation
import SwiftData

struct PresupuestoSnapshotItem: Codable, Identifiable {
    var id: String { "\(categoriaId)-\(moneda)" }
    let categoriaId: String
    let categoriaNombre: String
    let categoriaIcono: String
    let montoPresupuestado: Double
    let gastoReal: Double
    let moneda: String
}

@Model
final class MesCerrado {
    var id: UUID
    var mes: Int
    var anho: Int
    var balanceVES: Double
    var balanceUSD: Double
    var ingresosTotalesVES: Double
    var ingresosTotalesUSD: Double
    var gastosTotalesVES: Double
    var gastosTotalesUSD: Double
    var tasaAhorro: Double
    var transaccionCount: Int
    var fechaCierre: Date

    var presupuestosSnapshotData: Data?

    var presupuestosSnapshot: [PresupuestoSnapshotItem] {
        get {
            guard let data = presupuestosSnapshotData else { return [] }
            return (try? JSONDecoder().decode([PresupuestoSnapshotItem].self, from: data)) ?? []
        }
        set {
            presupuestosSnapshotData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        id: UUID = UUID(),
        mes: Int,
        anho: Int,
        balanceVES: Double,
        balanceUSD: Double,
        ingresosTotalesVES: Double,
        ingresosTotalesUSD: Double,
        gastosTotalesVES: Double,
        gastosTotalesUSD: Double,
        tasaAhorro: Double = 0,
        transaccionCount: Int = 0,
        presupuestosSnapshot: [PresupuestoSnapshotItem] = [],
        fechaCierre: Date = Date()
    ) {
        self.id = id
        self.mes = mes
        self.anho = anho
        self.balanceVES = balanceVES
        self.balanceUSD = balanceUSD
        self.ingresosTotalesVES = ingresosTotalesVES
        self.ingresosTotalesUSD = ingresosTotalesUSD
        self.gastosTotalesVES = gastosTotalesVES
        self.gastosTotalesUSD = gastosTotalesUSD
        self.tasaAhorro = tasaAhorro
        self.transaccionCount = transaccionCount
        self.fechaCierre = fechaCierre
        self.presupuestosSnapshot = presupuestosSnapshot
    }
}
