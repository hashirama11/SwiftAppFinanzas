import XCTest
@testable import FinanzasIOS

final class BudgetViewModelTests: XCTestCase {
    var mockRepository: MockFinanzasRepository!
    var sut: BudgetViewModel!

    @MainActor
    override func setUp() async throws {
        mockRepository = MockFinanzasRepository()
        sut = BudgetViewModel(repository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
    }

    // MARK: - Load Data

    @MainActor
    func testLoadData_empty_returnsEmptyPresupuestos() async {
        mockRepository.seed(categorias: [])
        mockRepository.seed(transacciones: [])
        mockRepository.seed(presupuestos: [])

        await sut.loadData()

        XCTAssertFalse(sut.state.isLoading)
        XCTAssertTrue(sut.state.categorias.isEmpty)
        XCTAssertTrue(sut.state.presupuestos.isEmpty)
        XCTAssertTrue(sut.state.categoriasConPresupuesto.isEmpty)
    }

    @MainActor
    func testLoadData_withPresupuesto_returnsInList() async {
        let cat = TestFactory.makeCategoria(nombre: "Supermercado", tipo: .gasto)
        let presupuesto = TestFactory.makePresupuestoCategoria(
            categoria: cat,
            mes: sut.state.mesSeleccionado,
            anho: sut.state.anhoSeleccionado,
            monto: 300,
            moneda: .VES
        )
        mockRepository.seed(categorias: [cat])
        mockRepository.seed(transacciones: [])
        mockRepository.seed(presupuestos: [presupuesto])

        await sut.loadData()

        XCTAssertEqual(sut.state.categoriasConPresupuesto.count, 1)
        let item = sut.state.categoriasConPresupuesto.first!
        XCTAssertEqual(item.montoPresupuestado, 300)
        XCTAssertEqual(item.gastoReal, 0)
        XCTAssertEqual(item.porcentaje, 0)
    }

    @MainActor
    func testLoadData_withTransactions_computesGastoReal() async {
        let cat = TestFactory.makeCategoria(nombre: "Supermercado", tipo: .gasto)
        let tx = TestFactory.makeTransaccion(monto: 150, moneda: .VES, tipo: .gasto, categoria: cat)

        let calendar = Calendar.current
        let now = Date()
        let mes = calendar.component(.month, from: now)
        let anho = calendar.component(.year, from: now)

        let presupuesto = TestFactory.makePresupuestoCategoria(
            categoria: cat,
            mes: mes,
            anho: anho,
            monto: 300,
            moneda: .VES
        )

        mockRepository.seed(categorias: [cat])
        mockRepository.seed(transacciones: [tx])
        mockRepository.seed(presupuestos: [presupuesto])

        sut.state.mesSeleccionado = mes
        sut.state.anhoSeleccionado = anho
        await sut.loadData()

        let item = sut.state.categoriasConPresupuesto.first!
        XCTAssertEqual(item.gastoReal, 150)
        XCTAssertEqual(item.porcentaje, 0.5)
    }

    // MARK: - Filtering

    @MainActor
    func testFiltroTipo_onlyShowsMatchingCategories() async {
        let catGasto = TestFactory.makeCategoria(nombre: "Comida", tipo: .gasto)
        let catIngreso = TestFactory.makeCategoria(nombre: "Salario", tipo: .ingreso)
        let p1 = TestFactory.makePresupuestoCategoria(categoria: catGasto, monto: 100, moneda: .VES)
        let p2 = TestFactory.makePresupuestoCategoria(categoria: catIngreso, monto: 500, moneda: .VES)

        mockRepository.seed(categorias: [catGasto, catIngreso])
        mockRepository.seed(transacciones: [])
        mockRepository.seed(presupuestos: [p1, p2])

        await sut.loadData()
        sut.cambiarTipo("ingreso")

        XCTAssertEqual(sut.state.categoriasConPresupuesto.count, 1)
        XCTAssertEqual(sut.state.categoriasConPresupuesto.first?.categoria.nombre, "Salario")
    }

    @MainActor
    func testCompositeKey_separatesByMoneda() async {
        let cat = TestFactory.makeCategoria(nombre: "Supermercado", tipo: .gasto)
        let pVES = TestFactory.makePresupuestoCategoria(categoria: cat, monto: 300, moneda: .VES)
        let pUSD = TestFactory.makePresupuestoCategoria(categoria: cat, monto: 100, moneda: .USD)

        mockRepository.seed(categorias: [cat])
        mockRepository.seed(transacciones: [])
        mockRepository.seed(presupuestos: [pVES, pUSD])

        await sut.loadData()

        let keyVES = sut.state.presupuestoKey(categoriaId: cat.id, moneda: "VES")
        let keyUSD = sut.state.presupuestoKey(categoriaId: cat.id, moneda: "USD")
        XCTAssertNotNil(sut.state.presupuestos[keyVES])
        XCTAssertNotNil(sut.state.presupuestos[keyUSD])
        XCTAssertEqual(sut.state.presupuestos[keyVES]?.monto, 300)
        XCTAssertEqual(sut.state.presupuestos[keyUSD]?.monto, 100)
    }

    // MARK: - Totals

    @MainActor
    func testTotalPresupuestado_sumsCorrectly() async {
        let cat1 = TestFactory.makeCategoria(nombre: "A", tipo: .gasto)
        let cat2 = TestFactory.makeCategoria(nombre: "B", tipo: .gasto)
        let p1 = TestFactory.makePresupuestoCategoria(categoria: cat1, monto: 200, moneda: .VES)
        let p2 = TestFactory.makePresupuestoCategoria(categoria: cat2, monto: 300, moneda: .VES)

        mockRepository.seed(categorias: [cat1, cat2])
        mockRepository.seed(transacciones: [])
        mockRepository.seed(presupuestos: [p1, p2])

        await sut.loadData()

        sut.state.monedaFiltro = "VES"
        XCTAssertEqual(sut.state.totalPresupuestado, 500)
    }

    @MainActor
    func testCategoriaSinPresupuesto_notInList() async {
        let cat = TestFactory.makeCategoria(nombre: "Sin presupuesto", tipo: .gasto)

        mockRepository.seed(categorias: [cat])
        mockRepository.seed(transacciones: [])
        mockRepository.seed(presupuestos: [])

        await sut.loadData()

        XCTAssertTrue(sut.state.categoriasConPresupuesto.isEmpty)
    }
}
