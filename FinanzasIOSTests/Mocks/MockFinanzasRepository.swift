import Foundation
@testable import FinanzasIOS

final class MockFinanzasRepository: FinanzasRepository {
    private var transacciones: [Transaccion] = []
    private var categorias: [Categoria] = []
    private var usuario: Usuario?
    private var presupuestos: [PresupuestoCategoria] = []
    private var mesesCerrados: [MesCerrado] = []

    var didInsertTransaccion = false
    var didUpdateTransaccion = false
    var didDeleteTransaccion = false
    var didInsertCategoria = false
    var didDeleteCategoria = false
    var didUpsertUsuario = false
    var didUpsertPresupuesto = false

    func seed(transacciones: [Transaccion]) { self.transacciones = transacciones }
    func seed(categorias: [Categoria]) { self.categorias = categorias }
    func seed(usuario: Usuario) { self.usuario = usuario }
    func seed(presupuestos: [PresupuestoCategoria]) { self.presupuestos = presupuestos }

    func getAllTransacciones() async throws -> [Transaccion] { transacciones }

    func getTransaccionesPaginadas(limit: Int, offset: Int, tipo: String?, filtroTexto: String?) async throws -> [Transaccion] {
        var filtered = transacciones
        if let tipo = tipo { filtered = filtered.filter { $0.tipo == tipo } }
        if let texto = filtroTexto, !texto.isEmpty {
            filtered = filtered.filter {
                $0.descripcion.localizedCaseInsensitiveContains(texto) ||
                ($0.categoria?.nombre ?? "").localizedCaseInsensitiveContains(texto)
            }
        }
        let start = min(offset, filtered.count)
        let end = min(offset + limit, filtered.count)
        guard start < end else { return [] }
        return Array(filtered[start..<end])
    }

    func getTransaccionesCount(tipo: String?) async throws -> Int {
        if let tipo = tipo { return transacciones.filter { $0.tipo == tipo }.count }
        return transacciones.count
    }

    func insertTransaccion(_ transaccion: Transaccion) async throws {
        transacciones.append(transaccion)
        didInsertTransaccion = true
    }

    func updateTransaccion(_ transaccion: Transaccion) async throws {
        if let index = transacciones.firstIndex(where: { $0.id == transaccion.id }) {
            transacciones[index] = transaccion
        }
        didUpdateTransaccion = true
    }

    func deleteTransaccion(_ transaccion: Transaccion) async throws {
        transacciones.removeAll { $0.id == transaccion.id }
        didDeleteTransaccion = true
    }

    func deleteTransaccion(by id: UUID) async throws {
        transacciones.removeAll { $0.id == id }
        didDeleteTransaccion = true
    }

    func getTransaccion(by id: UUID) async throws -> Transaccion? {
        transacciones.first { $0.id == id }
    }

    func getAllCategorias() async throws -> [Categoria] { categorias }

    func insertCategoria(_ categoria: Categoria) async throws {
        categorias.append(categoria)
        didInsertCategoria = true
    }

    func updateCategoria(_ categoria: Categoria) async throws {
        if let index = categorias.firstIndex(where: { $0.id == categoria.id }) {
            categorias[index] = categoria
        }
    }

    func deleteCategoria(_ categoria: Categoria) async throws {
        categorias.removeAll { $0.id == categoria.id }
        didDeleteCategoria = true
    }

    func getUsuario() async throws -> Usuario? { usuario }

    func upsertUsuario(_ usuario: Usuario) async throws {
        self.usuario = usuario
        didUpsertUsuario = true
    }

    func getPresupuestos(mes: Int, anho: Int) async throws -> [PresupuestoCategoria] {
        presupuestos.filter { $0.mes == mes && $0.anho == anho }
    }

    func getPresupuesto(categoriaId: UUID, mes: Int, anho: Int) async throws -> PresupuestoCategoria? {
        presupuestos.first { $0.categoriaId == categoriaId && $0.mes == mes && $0.anho == anho }
    }

    func upsertPresupuesto(_ presupuesto: PresupuestoCategoria) async throws {
        if let index = presupuestos.firstIndex(where: {
            $0.categoriaId == presupuesto.categoriaId &&
            $0.mes == presupuesto.mes &&
            $0.anho == presupuesto.anho &&
            $0.moneda == presupuesto.moneda
        }) {
            presupuestos[index].monto = presupuesto.monto
            presupuestos[index].categoriaId = presupuesto.categoriaId
        } else {
            presupuestos.append(presupuesto)
        }
        didUpsertPresupuesto = true
    }

    func deletePresupuesto(_ presupuesto: PresupuestoCategoria) async throws {
        presupuestos.removeAll { $0.id == presupuesto.id }
    }

    func getAllMesesCerrados() async throws -> [MesCerrado] {
        mesesCerrados.sorted { $0.fechaCierre > $1.fechaCierre }
    }

    func getMesCerrado(mes: Int, anho: Int) async throws -> MesCerrado? {
        mesesCerrados.first { $0.mes == mes && $0.anho == anho }
    }
}
