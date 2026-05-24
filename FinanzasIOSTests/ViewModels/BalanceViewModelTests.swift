import XCTest
@testable import FinanzasIOS

final class BalanceViewModelTests: XCTestCase {
    var mockRepository: MockFinanzasRepository!
    var sut: BalanceViewModel!

    @MainActor
    override func setUp() async throws {
        mockRepository = MockFinanzasRepository()
        sut = BalanceViewModel(repository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
    }

    @MainActor
    func testLoadData_empty_setsZeroState() async {
        mockRepository.seed(transacciones: [])

        await sut.loadData()

        XCTAssertFalse(sut.state.isLoading)
        XCTAssertEqual(sut.state.totalIngresosVes, 0)
        XCTAssertEqual(sut.state.totalGastosVes, 0)
        XCTAssertEqual(sut.state.balanceNetoVes, 0)
        XCTAssertEqual(sut.state.tasaAhorro, 0)
        XCTAssertEqual(sut.state.monthlyFlows.count, 6)
    }

    @MainActor
    func testLoadData_singleIncomeVES_computesCorrectNetBalance() async {
        let tx = TestFactory.makeTransaccion(monto: 500, moneda: .VES, tipo: .ingreso)
        mockRepository.seed(transacciones: [tx])

        await sut.loadData()

        XCTAssertEqual(sut.state.totalIngresosVes, 500)
        XCTAssertEqual(sut.state.balanceNetoVes, 500)
        XCTAssertEqual(sut.state.tasaAhorro, 1.0)
    }

    @MainActor
    func testLoadData_singleExpenseUSD_computesNegativeBalance() async {
        let tx = TestFactory.makeTransaccion(monto: 100, moneda: .USD, tipo: .gasto)
        mockRepository.seed(transacciones: [tx])

        await sut.loadData()

        XCTAssertEqual(sut.state.totalGastosUsd, 100)
        XCTAssertEqual(sut.state.balanceNetoUsd, -100)
        XCTAssertEqual(sut.state.tasaAhorro, 0.0)
    }

    @MainActor
    func testLoadData_mixedIncomeExpense_computesCorrectSavingsRate() async {
        let ingreso = TestFactory.makeTransaccion(monto: 1000, moneda: .VES, tipo: .ingreso)
        let gasto = TestFactory.makeTransaccion(monto: 400, moneda: .VES, tipo: .gasto)
        mockRepository.seed(transacciones: [ingreso, gasto])

        await sut.loadData()

        XCTAssertEqual(sut.state.balanceNetoVes, 600)
        XCTAssertEqual(sut.state.tasaAhorro, 0.6)
    }

    @MainActor
    func testLoadData_savingsRateBoundedZeroToOne() async {
        let gasto = TestFactory.makeTransaccion(monto: 2000, moneda: .VES, tipo: .gasto)
        mockRepository.seed(transacciones: [gasto])

        await sut.loadData()

        XCTAssertEqual(sut.state.tasaAhorro, 0.0)
    }

    @MainActor
    func testLoadData_dualCurrency_computesSeparately() async {
        let ingresoVes = TestFactory.makeTransaccion(monto: 1000, moneda: .VES, tipo: .ingreso)
        let ingresoUsd = TestFactory.makeTransaccion(monto: 500, moneda: .USD, tipo: .ingreso)
        let gastoVes = TestFactory.makeTransaccion(monto: 300, moneda: .VES, tipo: .gasto)
        let gastoUsd = TestFactory.makeTransaccion(monto: 200, moneda: .USD, tipo: .gasto)

        mockRepository.seed(transacciones: [ingresoVes, ingresoUsd, gastoVes, gastoUsd])

        await sut.loadData()

        XCTAssertEqual(sut.state.totalIngresosVes, 1000)
        XCTAssertEqual(sut.state.totalIngresosUsd, 500)
        XCTAssertEqual(sut.state.totalGastosVes, 300)
        XCTAssertEqual(sut.state.totalGastosUsd, 200)
        XCTAssertEqual(sut.state.balanceNetoVes, 700)
        XCTAssertEqual(sut.state.balanceNetoUsd, 300)
    }

    @MainActor
    func testMonthlyFlows_generatesSixMonthsBack() async {
        mockRepository.seed(transacciones: [])

        await sut.loadData()

        XCTAssertEqual(sut.state.monthlyFlows.count, 6)
        for flow in sut.state.monthlyFlows {
            XCTAssertEqual(flow.ingresos, 0)
            XCTAssertEqual(flow.gastos, 0)
        }
    }
}
