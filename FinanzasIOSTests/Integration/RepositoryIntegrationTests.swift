import XCTest
import SwiftData
@testable import FinanzasIOS

final class RepositoryIntegrationTests: XCTestCase {
    var modelContainer: ModelContainer!
    var sut: FinanzasRepositoryImpl!

    @MainActor
    override func setUp() async throws {
        let schema = Schema([Usuario.self, Categoria.self, Transaccion.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        sut = FinanzasRepositoryImpl(modelContext: modelContainer.mainContext)
    }

    override func tearDown() {
        modelContainer = nil
        sut = nil
    }

    @MainActor
    func testInsertAndRetrieveTransaccion() async throws {
        let categoria = Categoria(nombre: "Test", icono: .supermercado, tipo: .gasto)
        try await sut.insertCategoria(categoria)

        let tx = Transaccion(monto: 100, moneda: .VES, descripcion: "Test", tipo: .gasto, categoria: categoria)
        try await sut.insertTransaccion(tx)

        let all = try await sut.getAllTransacciones()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.descripcion, "Test")
        XCTAssertEqual(all.first?.categoria?.nombre, "Test")
    }

    @MainActor
    func testDeleteTransaccion_byId() async throws {
        let tx = Transaccion(monto: 50, moneda: .USD, descripcion: "Para borrar", tipo: .gasto)
        try await sut.insertTransaccion(tx)

        var all = try await sut.getAllTransacciones()
        XCTAssertEqual(all.count, 1)

        try await sut.deleteTransaccion(by: tx.id)

        all = try await sut.getAllTransacciones()
        XCTAssertEqual(all.count, 0)
    }

    @MainActor
    func testUpdateTransaccion() async throws {
        let tx = Transaccion(monto: 50, moneda: .VES, descripcion: "Original", tipo: .gasto)
        try await sut.insertTransaccion(tx)

        tx.descripcion = "Modificado"
        tx.monto = 75
        try await sut.updateTransaccion(tx)

        let fetched = try await sut.getTransaccion(by: tx.id)
        XCTAssertEqual(fetched?.descripcion, "Modificado")
        XCTAssertEqual(fetched?.monto, 75)
    }

    @MainActor
    func testGetAllCategorias_returnsSeeded() async throws {
        let cat1 = Categoria(nombre: "Cat A", icono: .supermercado, tipo: .gasto)
        let cat2 = Categoria(nombre: "Cat B", icono: .restaurantes, tipo: .gasto)
        try await sut.insertCategoria(cat1)
        try await sut.insertCategoria(cat2)

        let all = try await sut.getAllCategorias()
        XCTAssertEqual(all.count, 2)
    }

    @MainActor
    func testUpsertUsuario_createsAndUpdates() async throws {
        let user = Usuario(id: 1, nombre: "Original", tema: .claro, onboardingCompletado: false)
        try await sut.upsertUsuario(user)

        var fetched = try await sut.getUsuario()
        XCTAssertEqual(fetched?.nombre, "Original")

        let updated = Usuario(id: 1, nombre: "Actualizado", tema: .oscuro, onboardingCompletado: true)
        try await sut.upsertUsuario(updated)

        fetched = try await sut.getUsuario()
        XCTAssertEqual(fetched?.nombre, "Actualizado")
        XCTAssertTrue(fetched?.isDarkTheme ?? false)
    }

    @MainActor
    func testFetchDescriptor_sortsByDateReverse() async throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tx1 = Transaccion(monto: 100, descripcion: "Reciente", fecha: Date(), tipo: .gasto)
        let tx2 = Transaccion(monto: 200, descripcion: "Antiguo", fecha: yesterday, tipo: .gasto)
        try await sut.insertTransaccion(tx1)
        try await sut.insertTransaccion(tx2)

        let all = try await sut.getAllTransacciones()
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all.first?.descripcion, "Reciente")
    }

    @MainActor
    func testCategoriaRelationship_nullifyOnDelete() async throws {
        let cat = Categoria(nombre: "Test", icono: .supermercado, tipo: .gasto)
        try await sut.insertCategoria(cat)

        let tx = Transaccion(monto: 100, moneda: .VES, descripcion: "Con categoria", tipo: .gasto, categoria: cat)
        try await sut.insertTransaccion(tx)

        try await sut.deleteCategoria(cat)

        let fetched = try await sut.getTransaccion(by: tx.id)
        XCTAssertNil(fetched?.categoria)
    }

    @MainActor
    func testDefaultSeeder_createsUsuario() async throws {
        await DefaultDataSeeder.seedIfNeeded(context: modelContainer.mainContext)

        let usuario = try await sut.getUsuario()
        XCTAssertNotNil(usuario)
        XCTAssertEqual(usuario?.nombre, "Usuario")
        XCTAssertFalse(usuario?.onboardingCompletado ?? true)
    }

    @MainActor
    func testDefaultSeeder_createsCategorias() async throws {
        await DefaultDataSeeder.seedIfNeeded(context: modelContainer.mainContext)

        let categorias = try await sut.getAllCategorias()
        XCTAssertGreaterThan(categorias.count, 10)
        XCTAssertTrue(categorias.contains { $0.nombre == "Ingreso General" })
        XCTAssertTrue(categorias.contains { $0.nombre == "Supermercado" })
    }
}
