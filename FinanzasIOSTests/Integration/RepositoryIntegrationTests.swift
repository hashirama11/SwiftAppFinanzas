import XCTest
import SwiftData
@testable import FinanzasIOS

final class RepositoryIntegrationTests: XCTestCase {
    var modelContainer: ModelContainer!
    var sut: FinanzasRepositoryImpl!

    @MainActor
    override func setUp() async throws {
        let schema = Schema([Usuario.self, Categoria.self, Transaccion.self, PresupuestoCategoria.self, MesCerrado.self])
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
        XCTAssertTrue(categorias.contains { $0.nombre == "Salario" })
        XCTAssertTrue(categorias.contains { $0.nombre == "Supermercado" })
    }

    @MainActor
    func testUpsertPresupuesto_createsAndUpdates() async throws {
        let cat = Categoria(nombre: "Comida", icono: .supermercado, tipo: .gasto)
        try await sut.insertCategoria(cat)

        let presupuesto = PresupuestoCategoria(
            categoria: cat,
            mes: 5,
            anho: 2026,
            monto: 300,
            moneda: .VES,
            esRecurrente: true
        )
        try await sut.upsertPresupuesto(presupuesto)

        let all = try await sut.getPresupuestos(mes: 5, anho: 2026)
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.monto, 300)
        XCTAssertTrue(all.first?.esRecurrente ?? false)
    }

    @MainActor
    func testPresupuesto_filteredByMesAnho() async throws {
        let cat = Categoria(nombre: "Comida", icono: .supermercado, tipo: .gasto)
        try await sut.insertCategoria(cat)

        let pMayo = PresupuestoCategoria(categoria: cat, mes: 5, anho: 2026, monto: 200, moneda: .VES)
        let pJunio = PresupuestoCategoria(categoria: cat, mes: 6, anho: 2026, monto: 250, moneda: .VES)
        try await sut.upsertPresupuesto(pMayo)
        try await sut.upsertPresupuesto(pJunio)

        let mayo = try await sut.getPresupuestos(mes: 5, anho: 2026)
        let junio = try await sut.getPresupuestos(mes: 6, anho: 2026)
        XCTAssertEqual(mayo.count, 1)
        XCTAssertEqual(junio.count, 1)
        XCTAssertEqual(mayo.first?.monto, 200)
        XCTAssertEqual(junio.first?.monto, 250)
    }

    @MainActor
    func testDeletePresupuesto_removesCorrectly() async throws {
        let cat = Categoria(nombre: "Comida", icono: .supermercado, tipo: .gasto)
        try await sut.insertCategoria(cat)

        let p = PresupuestoCategoria(categoria: cat, mes: 5, anho: 2026, monto: 200, moneda: .VES)
        try await sut.upsertPresupuesto(p)

        try await sut.deletePresupuesto(p)
        let all = try await sut.getPresupuestos(mes: 5, anho: 2026)
        XCTAssertEqual(all.count, 0)
    }

    @MainActor
    func testMesCerrado_archiveAndRetrieve() async throws {
        let mes = MesCerrado(
            mes: 4,
            anho: 2026,
            balanceVES: 500,
            balanceUSD: 100,
            ingresosTotalesVES: 1000,
            ingresosTotalesUSD: 200,
            gastosTotalesVES: 500,
            gastosTotalesUSD: 100,
            tasaAhorro: 0.5,
            transaccionCount: 10
        )
        modelContainer.mainContext.insert(mes)
        try modelContainer.mainContext.save()

        let all = try await sut.getAllMesesCerrados()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.mes, 4)
        XCTAssertEqual(all.first?.balanceVES, 500)
    }

    @MainActor
    func testPaginacion_respectsLimitOffset() async throws {
        for i in 0..<30 {
            let tx = Transaccion(monto: Double(i), descripcion: "Tx \(i)", tipo: .gasto)
            try await sut.insertTransaccion(tx)
        }

        let page1 = try await sut.getTransaccionesPaginadas(limit: 20, offset: 0, tipo: "gasto", filtroTexto: nil)
        let page2 = try await sut.getTransaccionesPaginadas(limit: 20, offset: 20, tipo: "gasto", filtroTexto: nil)

        XCTAssertEqual(page1.count, 20)
        XCTAssertEqual(page2.count, 10)
    }
}
