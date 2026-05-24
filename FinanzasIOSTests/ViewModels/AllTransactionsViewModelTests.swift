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

        await sut.loadData()

        XCTAssertFalse(sut.state.isLoading)
        XCTAssertTrue(sut.state.allTransactions.isEmpty)
        XCTAssertTrue(sut.state.filteredTransactions.isEmpty)
    }

    @MainActor
    func testLoadData_singleTransaction_returnsInList() async {
        let tx = TestFactory.makeTransaccion(monto: 100, descripcion: "Test")
        mockRepository.seed(transacciones: [tx])

        await sut.loadData()

        XCTAssertEqual(sut.state.allTransactions.count, 1)
        XCTAssertEqual(sut.state.filteredTransactions.count, 1)
        XCTAssertEqual(sut.state.filteredTransactions.first?.transaccion.descripcion, "Test")
    }

    @MainActor
    func testSearchQuery_filtersByDescription() async {
        let tx1 = TestFactory.makeTransaccion(descripcion: "Supermercado")
        let tx2 = TestFactory.makeTransaccion(descripcion: "Restaurante")
        mockRepository.seed(transacciones: [tx1, tx2])

        await sut.loadData()
        sut.onSearchQueryChange("super")

        XCTAssertEqual(sut.state.filteredTransactions.count, 1)
        XCTAssertEqual(sut.state.filteredTransactions.first?.transaccion.descripcion, "Supermercado")
    }

    @MainActor
    func testSearchQuery_filtersByCategoryName() async {
        let cat = TestFactory.makeCategoria(nombre: "Comida")
        let tx = TestFactory.makeTransaccion(descripcion: "Almuerzo", categoria: cat)
        mockRepository.seed(transacciones: [tx])
        mockRepository.seed(categorias: [cat])

        await sut.loadData()
        sut.onSearchQueryChange("comi")

        XCTAssertEqual(sut.state.filteredTransactions.count, 1)
    }

    @MainActor
    func testSearchQuery_empty_returnsAll() async {
        let tx1 = TestFactory.makeTransaccion(descripcion: "A")
        let tx2 = TestFactory.makeTransaccion(descripcion: "B")
        mockRepository.seed(transacciones: [tx1, tx2])

        await sut.loadData()
        sut.onSearchQueryChange("")

        XCTAssertEqual(sut.state.filteredTransactions.count, 2)
    }

    @MainActor
    func testFilterType_toggleFiltersByType() async {
        let ingreso = TestFactory.makeTransaccion(descripcion: "Salario", tipo: .ingreso)
        let gasto = TestFactory.makeTransaccion(descripcion: "Compra", tipo: .gasto)
        mockRepository.seed(transacciones: [ingreso, gasto])

        await sut.loadData()

        sut.onFilterTypeChange(.ingreso)
        XCTAssertEqual(sut.state.filteredTransactions.count, 1)
        XCTAssertEqual(sut.state.filteredTransactions.first?.transaccion.descripcion, "Salario")

        sut.onFilterTypeChange(.ingreso)
        XCTAssertEqual(sut.state.filteredTransactions.count, 2)
    }

    @MainActor
    func testSearchAndFilterCombined_narrowsCorrectly() async {
        let ingreso = TestFactory.makeTransaccion(descripcion: "Salario", tipo: .ingreso)
        let gasto = TestFactory.makeTransaccion(descripcion: "Supermercado", tipo: .gasto)
        mockRepository.seed(transacciones: [ingreso, gasto])

        await sut.loadData()

        sut.onSearchQueryChange("sal")
        sut.onFilterTypeChange(.ingreso)

        XCTAssertEqual(sut.state.filteredTransactions.count, 1)
        XCTAssertEqual(sut.state.filteredTransactions.first?.transaccion.descripcion, "Salario")
    }
}
