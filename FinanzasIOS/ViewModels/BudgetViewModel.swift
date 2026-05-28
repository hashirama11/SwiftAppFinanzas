import Foundation
import Observation

@Observable
final class BudgetViewModel {
    var state = BudgetState()
    var errorMessage: String?

    private let repository: FinanzasRepository

    init(repository: FinanzasRepository) {
        self.repository = repository
    }

    func loadData() async {
        state.isLoading = true
        errorMessage = nil

        let categorias: [Categoria]
        let transacciones: [Transaccion]
        let presupuestos: [PresupuestoCategoria]
        do {
            categorias = try await repository.getAllCategorias()
            transacciones = try await repository.getAllTransacciones()
            presupuestos = try await repository.getPresupuestos(
                mes: state.mesSeleccionado,
                anho: state.anhoSeleccionado
            )
        } catch {
            state.isLoading = false
            errorMessage = "Error al cargar datos: \(error.localizedDescription)"
            return
        }

        var newState = state
        newState.categorias = categorias

        var presupuestoMap: [String: PresupuestoCategoria] = [:]
        for p in presupuestos {
            if let catId = p.categoriaId {
                let key = newState.presupuestoKey(categoriaId: catId, moneda: p.moneda)
                presupuestoMap[key] = p
            }
        }
        newState.presupuestos = presupuestoMap

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = state.anhoSeleccionado
        components.month = state.mesSeleccionado
        components.day = 1
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            state.isLoading = false
            return
        }

        let txDelMes = transacciones.filter { $0.fecha >= startOfMonth && $0.fecha <= endOfMonth }

        var gastoMap: [UUID: Double] = [:]
        for cat in categorias {
            let total = txDelMes
                .filter { $0.categoria?.id == cat.id }
                .reduce(0) { $0 + $1.monto }
            gastoMap[cat.id] = total
        }
        newState.gastoReal = gastoMap
        newState.isLoading = false
        state = newState
    }

    func cambiarMes(a mes: Int, anho: Int) {
        state.mesSeleccionado = mes
        state.anhoSeleccionado = anho
        Task { await loadData() }
    }

    func cambiarMoneda(_ moneda: String) {
        state.monedaFiltro = moneda
    }

    func cambiarTipo(_ tipo: String) {
        state.tipoFiltro = tipo
    }
}
