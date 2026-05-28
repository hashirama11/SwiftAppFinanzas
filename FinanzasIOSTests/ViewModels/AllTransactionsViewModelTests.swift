import XCTest
@testable import FinanzasIOS

final class AllTransactionsViewModelTests: XCTestCase {
    var mockRepository: MockFinanzasRepository!
    var sut: AllTransactionsViewModel!

    @MainActor
    override func setUp() async throws {
        mockRepository = MockFinanzasRepository()
        sut = AllTransactionsViewModel(repository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
    }

    @MainActor
    func testLoadData_empty_returnsEmptyList() async {
        mockRepository.seed(transacciones: [])

        await sut.loadInitialData()

        XCTAssertFalse(sut.state.isLoading)
        XCTAssertTrue(sut.state.transactions.isEmpty)
        XCTAssertFalse(sut.state.hasMorePages)
    }

    @MainActor
    func testLoadData_singleTransaction_returnsInList() async {
        let tx = TestFactory.makeTransaccion(monto: 100, descripcion: "Test")
        mockRepository.seed(transacciones: [tx])

        await sut.loadInitialData()

        XCTAssertEqual(sut.state.transactions.count, 1)
        XCTAssertEqual(sut.state.transactions.first?.transaccion.descripcion, "Test")
    }

    @MainActor
    func testSearchQuery_filtersByDescription() async {
        let tx1 = TestFactory.makeTransaccion(descripcion: "Supermercado")
        let tx2 = TestFactory.makeTransaccion(descripcion: "Restaurante")
        mockRepository.seed(transacciones: [tx1, tx2])

        await sut.loadInitialData()
        sut.onSearchQueryChange("super")

        XCTAssertEqual(sut.state.transactions.count, 1)
        XCTAssertEqual(sut.state.transactions.first?.transaccion.descripcion, "Supermercado")
    }

    @MainActor
    func testFilterType_toggleFiltersByType() async {
        let ingreso = TestFactory.makeTransaccion(descripcion: "Salario", tipo: .ingreso)
        let gasto = TestFactory.makeTransaccion(descripcion: "Compra", tipo: .gasto)
        mockRepository.seed(transacciones: [ingreso, gasto])

        await sut.loadInitialData()

        sut.onFilterTypeChange(.ingreso)
        XCTAssertEqual(sut.state.transactions.count, 1)
        XCTAssertEqual(sut.state.transactions.first?.transaccion.descripcion, "Salario")

        sut.onFilterTypeChange(.ingreso)
        XCTAssertEqual(sut.state.transactions.count, 2)
    }

    @MainActor
    func testPagination_loadsMoreWhenAvailable() async {
        var txs: [Transaccion] = []
        for i in 0..<25 {
            txs.append(TestFactory.makeTransaccion(descripcion: "Tx \(i)"))
        }
        mockRepository.seed(transacciones: txs)

        await sut.loadInitialData()
        XCTAssertEqual(sut.state.transactions.count, 20)
        XCTAssertTrue(sut.state.hasMorePages)

        await sut.loadMore()
        XCTAssertEqual(sut.state.transactions.count, 25)
        XCTAssertFalse(sut.state.hasMorePages)
    }
}
