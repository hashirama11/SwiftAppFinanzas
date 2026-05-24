import XCTest
@testable import FinanzasIOS

final class DashboardViewModelTests: XCTestCase {
    var mockRepository: MockFinanzasRepository!
    var sut: DashboardViewModel!

    @MainActor
    override func setUp() async throws {
        mockRepository = MockFinanzasRepository()
        sut = DashboardViewModel(repository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
    }

    @MainActor
    func testLoadData_emptyRepository_setsEmptyState() async {
        mockRepository.seed(usuario: TestFactory.makeUsuario())

        await sut.loadData()

        XCTAssertFalse(sut.state.isLoading)
        XCTAssertEqual(sut.state.userName, "Test User")
        XCTAssertEqual(sut.state.totalIngresosVes, 0)
        XCTAssertEqual(sut.state.totalIngresosUsd, 0)
        XCTAssertEqual(sut.state.totalGastosVes, 0)
        XCTAssertEqual(sut.state.totalGastosUsd, 0)
        XCTAssertTrue(sut.state.incomeChartDataVes.isEmpty)
        XCTAssertTrue(sut.state.expenseChartDataVes.isEmpty)
        XCTAssertTrue(sut.state.incomeChartDataUsd.isEmpty)
        XCTAssertTrue(sut.state.expenseChartDataUsd.isEmpty)
    }

    @MainActor
    func testLoadData_singleIncomeVES_computesCorrectTotals() async {
        let categoria = TestFactory.makeCategoria(nombre: "Salario", tipo: .ingreso)
        let tx = TestFactory.makeTransaccion(
            monto: 500.0,
            moneda: .VES,
            descripcion: "Salario",
            tipo: .ingreso,
            categoria: categoria
        )
        mockRepository.seed(transacciones: [tx])
        mockRepository.seed(categorias: [categoria])
        mockRepository.seed(usuario: TestFactory.makeUsuario())

        await sut.loadData()

        XCTAssertEqual(sut.state.totalIngresosVes, 500.0)
        XCTAssertEqual(sut.state.totalIngresosUsd, 0.0)
        XCTAssertEqual(sut.state.totalGastosVes, 0.0)
        XCTAssertEqual(sut.state.totalGastosUsd, 0.0)
        XCTAssertEqual(sut.state.incomeChartDataVes.count, 1)
        XCTAssertEqual(sut.state.incomeChartDataVes.first?.value, 1.0)
        XCTAssertEqual(sut.state.incomeChartDataVes.first?.categoryName, "Salario")
        XCTAssertTrue(sut.state.incomeChartDataUsd.isEmpty)
    }

    @MainActor
    func testLoadData_mixedCurrenciesIncome_separatesChartsByCurrency() async {
        let catSalario = TestFactory.makeCategoria(nombre: "Salario", tipo: .ingreso)
        let catFreelance = TestFactory.makeCategoria(nombre: "Freelance", tipo: .ingreso)

        let txVes = TestFactory.makeTransaccion(
            monto: 1000.0, moneda: .VES, descripcion: "Salario VES",
            tipo: .ingreso, categoria: catSalario
        )
        let txUsd = TestFactory.makeTransaccion(
            monto: 200.0, moneda: .USD, descripcion: "Freelance USD",
            tipo: .ingreso, categoria: catFreelance
        )

        mockRepository.seed(transacciones: [txVes, txUsd])
        mockRepository.seed(categorias: [catSalario, catFreelance])
        mockRepository.seed(usuario: TestFactory.makeUsuario())

        await sut.loadData()

        XCTAssertEqual(sut.state.totalIngresosVes, 1000.0)
        XCTAssertEqual(sut.state.totalIngresosUsd, 200.0)
        XCTAssertEqual(sut.state.incomeChartDataVes.count, 1)
        XCTAssertEqual(sut.state.incomeChartDataVes.first?.categoryName, "Salario")
        XCTAssertEqual(sut.state.incomeChartDataUsd.count, 1)
        XCTAssertEqual(sut.state.incomeChartDataUsd.first?.categoryName, "Freelance")
    }

    @MainActor
    func testLoadData_mixedCurrenciesExpenses_separatesChartsByCurrency() async {
        let catSuper = TestFactory.makeCategoria(nombre: "Supermercado", tipo: .gasto)
        let catRest = TestFactory.makeCategoria(nombre: "Restaurante", tipo: .gasto)

        let txVes = TestFactory.makeTransaccion(
            monto: 300.0, moneda: .VES, descripcion: "Super VES",
            tipo: .gasto, categoria: catSuper
        )
        let txUsd = TestFactory.makeTransaccion(
            monto: 50.0, moneda: .USD, descripcion: "Rest USD",
            tipo: .gasto, categoria: catRest
        )

        mockRepository.seed(transacciones: [txVes, txUsd])
        mockRepository.seed(categorias: [catSuper, catRest])
        mockRepository.seed(usuario: TestFactory.makeUsuario())

        await sut.loadData()

        XCTAssertEqual(sut.state.totalGastosVes, 300.0)
        XCTAssertEqual(sut.state.totalGastosUsd, 50.0)
        XCTAssertEqual(sut.state.expenseChartDataVes.count, 1)
        XCTAssertEqual(sut.state.expenseChartDataVes.first?.categoryName, "Supermercado")
        XCTAssertEqual(sut.state.expenseChartDataUsd.count, 1)
        XCTAssertEqual(sut.state.expenseChartDataUsd.first?.categoryName, "Restaurante")
    }

    @MainActor
    func testLoadData_sameCategoryDifferentCurrencies_producesSeparateCharts() async {
        let cat = TestFactory.makeCategoria(nombre: "Supermercado", tipo: .gasto)
        let txVes = TestFactory.makeTransaccion(
            monto: 100.0, moneda: .VES, descripcion: "VES", tipo: .gasto, categoria: cat
        )
        let txUsd = TestFactory.makeTransaccion(
            monto: 50.0, moneda: .USD, descripcion: "USD", tipo: .gasto, categoria: cat
        )

        mockRepository.seed(transacciones: [txVes, txUsd])
        mockRepository.seed(categorias: [cat])
        mockRepository.seed(usuario: TestFactory.makeUsuario())

        await sut.loadData()

        XCTAssertEqual(sut.state.totalGastosVes, 100.0)
        XCTAssertEqual(sut.state.totalGastosUsd, 50.0)
        XCTAssertEqual(sut.state.expenseChartDataVes.count, 1)
        XCTAssertEqual(sut.state.expenseChartDataUsd.count, 1)
        XCTAssertEqual(sut.state.expenseChartDataVes.first?.value, 1.0)
        XCTAssertEqual(sut.state.expenseChartDataUsd.first?.value, 1.0)
    }

    @MainActor
    func testLoadData_chartDataSortedByValueDescending() async {
        let catA = TestFactory.makeCategoria(nombre: "AAA", tipo: .gasto)
        let catB = TestFactory.makeCategoria(nombre: "BBB", tipo: .gasto)
        let catC = TestFactory.makeCategoria(nombre: "CCC", tipo: .gasto)

        let txA = TestFactory.makeTransaccion(monto: 100, moneda: .VES, tipo: .gasto, categoria: catA)
        let txB = TestFactory.makeTransaccion(monto: 300, moneda: .VES, tipo: .gasto, categoria: catB)
        let txC = TestFactory.makeTransaccion(monto: 200, moneda: .VES, tipo: .gasto, categoria: catC)

        mockRepository.seed(transacciones: [txA, txB, txC])
        mockRepository.seed(categorias: [catA, catB, catC])
        mockRepository.seed(usuario: TestFactory.makeUsuario())

        await sut.loadData()

        let chart = sut.state.expenseChartDataVes
        XCTAssertEqual(chart.count, 3)
        XCTAssertEqual(chart[0].categoryName, "BBB")
        XCTAssertEqual(chart[1].categoryName, "CCC")
        XCTAssertEqual(chart[2].categoryName, "AAA")
    }

    @MainActor
    func testRefreshFromCache_recomputesWithoutFetching() async {
        let cat = TestFactory.makeCategoria(nombre: "Test", tipo: .gasto)
        let tx = TestFactory.makeTransaccion(monto: 100, moneda: .VES, tipo: .gasto, categoria: cat)

        mockRepository.seed(transacciones: [tx])
        mockRepository.seed(categorias: [cat])
        mockRepository.seed(usuario: TestFactory.makeUsuario())

        await sut.loadData()

        let previousTransactions = sut.state.transactionsWithDetails

        await sut.refreshFromCache()

        XCTAssertEqual(sut.state.transactionsWithDetails.count, previousTransactions.count)
        XCTAssertFalse(sut.state.isLoading)
    }
}
