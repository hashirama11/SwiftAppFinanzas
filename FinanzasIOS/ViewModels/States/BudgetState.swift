import Foundation

struct CategoriaPresupuestada: Identifiable {
    var id: UUID { categoria.id }
    let categoria: Categoria
    let montoPresupuestado: Double
    let moneda: String
    let gastoReal: Double

    var porcentaje: Double {
        guard montoPresupuestado > 0 else { return 0 }
        return min(gastoReal / montoPresupuestado, 1.0)
    }

    var restante: Double { montoPresupuestado - gastoReal }

    var estaExcedido: Bool { gastoReal > montoPresupuestado }
}

struct BudgetState {
    var categorias: [Categoria] = []
    var presupuestos: [String: PresupuestoCategoria] = [:]
    var gastoReal: [UUID: Double] = [:]
    var mesSeleccionado: Int
    var anhoSeleccionado: Int
    var monedaFiltro: String = "VES"
    var tipoFiltro: String = "gasto"
    var isLoading: Bool = true

    init() {
        let calendar = Calendar.current
        let now = Date()
        mesSeleccionado = calendar.component(.month, from: now)
        anhoSeleccionado = calendar.component(.year, from: now)
    }

    var mesNombre: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        let index = mesSeleccionado - 1
        if index >= 0, index < formatter.monthSymbols.count {
            return formatter.monthSymbols[index].capitalized
        }
        return ""
    }

    func presupuestoKey(categoriaId: UUID, moneda: String) -> String {
        "\(categoriaId.uuidString)-\(moneda)"
    }

    var categoriasConPresupuesto: [CategoriaPresupuestada] {
        categorias
            .filter { $0.tipo == tipoFiltro }
            .compactMap { cat in
                let key = presupuestoKey(categoriaId: cat.id, moneda: monedaFiltro)
                guard let p = presupuestos[key], p.monto > 0 else { return nil }
                return CategoriaPresupuestada(
                    categoria: cat,
                    montoPresupuestado: p.monto,
                    moneda: p.moneda,
                    gastoReal: gastoReal[cat.id] ?? 0
                )
            }
    }

    var totalPresupuestado: Double {
        categoriasConPresupuesto.reduce(0) { $0 + $1.montoPresupuestado }
    }

    var totalReal: Double {
        categoriasConPresupuesto.reduce(0) { $0 + $1.gastoReal }
    }

    var porcentajeGlobal: Double {
        guard totalPresupuestado > 0 else { return 0 }
        return min(totalReal / totalPresupuestado, 1.0)
    }
}
