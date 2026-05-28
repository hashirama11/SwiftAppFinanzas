import Foundation
import SwiftData

@MainActor
struct MonthTransitionService {

    static func checkAndTransition(context: ModelContext) async {
        let calendar = Calendar.current
        let now = Date()
        let currentMes = calendar.component(.month, from: now)
        let currentAnho = calendar.component(.year, from: now)

        let lastActiveKey = "lastActiveMonth"
        let lastActiveValue = UserDefaults.standard.string(forKey: lastActiveKey) ?? ""
        let currentValue = "\(currentAnho)-\(currentMes)"

        guard lastActiveValue != currentValue else { return }

        if !lastActiveValue.isEmpty {
            let parts = lastActiveValue.split(separator: "-")
            if parts.count == 2,
               let prevAnho = Int(parts[0]),
               let prevMes = Int(parts[1]) {
                await archiveMonth(
                    context: context,
                    mes: prevMes,
                    anho: prevAnho
                )
                await copyRecurringBudgets(
                    context: context,
                    fromMes: prevMes,
                    fromAnho: prevAnho,
                    toMes: currentMes,
                    toAnho: currentAnho
                )
            }
        }

        UserDefaults.standard.set(currentValue, forKey: lastActiveKey)
    }

    private static func archiveMonth(
        context: ModelContext,
        mes: Int,
        anho: Int
    ) async {
        let repo = FinanzasRepositoryImpl(modelContext: context)

        guard let transacciones = try? await repo.getAllTransacciones(),
              let presupuestos = try? await repo.getPresupuestos(mes: mes, anho: anho),
              let categorias = try? await repo.getAllCategorias() else { return }

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = anho
        components.month = mes
        components.day = 1
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else { return }

        let txDelMes = transacciones.filter { $0.fecha >= startOfMonth && $0.fecha <= endOfMonth }

        var ingresosVES: Double = 0
        var ingresosUSD: Double = 0
        var gastosVES: Double = 0
        var gastosUSD: Double = 0

        for tx in txDelMes {
            if tx.tipoEnum == .ingreso {
                if tx.monedaEnum == .VES { ingresosVES += tx.monto }
                else { ingresosUSD += tx.monto }
            } else {
                if tx.monedaEnum == .VES { gastosVES += tx.monto }
                else { gastosUSD += tx.monto }
            }
        }

        let balanceVES = ingresosVES - gastosVES
        let balanceUSD = ingresosUSD - gastosUSD
        let totalIngresos = ingresosVES + ingresosUSD
        let balanceNeto = (ingresosVES + ingresosUSD) - (gastosVES + gastosUSD)
        let tasaAhorro: Double = totalIngresos > 0 ? max(0, min(1, balanceNeto / totalIngresos)) : 0

        var categoriasMap: [UUID: Categoria] = [:]
        for cat in categorias { categoriasMap[cat.id] = cat }

        var snapshotItems: [PresupuestoSnapshotItem] = []
        for p in presupuestos {
            guard let catId = p.categoriaId,
                  let cat = categoriasMap[catId] else { continue }

            let gasto = txDelMes
                .filter { $0.categoria?.id == catId && $0.monedaEnum.rawValue == p.moneda }
                .reduce(0) { $0 + $1.monto }

            snapshotItems.append(PresupuestoSnapshotItem(
                categoriaId: catId.uuidString,
                categoriaNombre: cat.nombre,
                categoriaIcono: cat.icono,
                montoPresupuestado: p.monto,
                gastoReal: gasto,
                moneda: p.moneda
            ))
        }

        let mesCerrado = MesCerrado(
            mes: mes,
            anho: anho,
            balanceVES: balanceVES,
            balanceUSD: balanceUSD,
            ingresosTotalesVES: ingresosVES,
            ingresosTotalesUSD: ingresosUSD,
            gastosTotalesVES: gastosVES,
            gastosTotalesUSD: gastosUSD,
            tasaAhorro: tasaAhorro,
            transaccionCount: txDelMes.count,
            presupuestosSnapshot: snapshotItems,
            fechaCierre: Date()
        )

        context.insert(mesCerrado)
        try? context.save()
    }

    private static func copyRecurringBudgets(
        context: ModelContext,
        fromMes: Int,
        fromAnho: Int,
        toMes: Int,
        toAnho: Int
    ) async {
        let repo = FinanzasRepositoryImpl(modelContext: context)

        guard let presupuestos = try? await repo.getPresupuestos(mes: fromMes, anho: fromAnho) else { return }

        for p in presupuestos where p.esRecurrente {
            let nuevo = PresupuestoCategoria(
                categoria: p.categoria,
                mes: toMes,
                anho: toAnho,
                monto: p.monto,
                moneda: p.monedaEnum,
                esRecurrente: true
            )
            try? await repo.upsertPresupuesto(nuevo)
        }
    }
}
