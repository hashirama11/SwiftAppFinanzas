import Foundation
@testable import FinanzasIOS

final class MockFinanzasRepository: FinanzasRepository {
    private var transacciones: [Transaccion] = []
    private var categorias: [Categoria] = []
    private var usuario: Usuario?

    var didInsertTransaccion = false
    var didUpdateTransaccion = false
    var didDeleteTransaccion = false
    var didInsertCategoria = false
    var didDeleteCategoria = false
    var didUpsertUsuario = false

    func seed(transacciones: [Transaccion]) { self.transacciones = transacciones }
    func seed(categorias: [Categoria]) { self.categorias = categorias }
    func seed(usuario: Usuario) { self.usuario = usuario }

    func getAllTransacciones() async throws -> [Transaccion] { transacciones }

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

    func deleteCategoria(_ categoria: Categoria) async throws {
        categorias.removeAll { $0.id == categoria.id }
        didDeleteCategoria = true
    }

    func getUsuario() async throws -> Usuario? { usuario }

    func upsertUsuario(_ usuario: Usuario) async throws {
        self.usuario = usuario
        didUpsertUsuario = true
    }
}
