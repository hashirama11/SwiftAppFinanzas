import XCTest
@testable import FinanzasIOS

final class AddTransactionViewModelTests: XCTestCase {
    var mockRepository: MockFinanzasRepository!
    var sut: AddTransactionViewModel!

    @MainActor
    override func setUp() async throws {
        mockRepository = MockFinanzasRepository()
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
    }

    @MainActor
    func testLoadForm_newTransaction_populatesCategoriesAndFilters() async {
        let catIngreso = TestFactory.makeCategoria(nombre: "Salario", tipo: .ingreso)
        let catGasto = TestFactory.makeCategoria(nombre: "Supermercado", tipo: .gasto)
        mockRepository.seed(categorias: [catIngreso, catGasto])

        sut = AddTransactionViewModel(repository: mockRepository)
        await sut.loadForm()

        XCTAssertEqual(sut.state.allCategories.count, 2)
        XCTAssertEqual(sut.state.filteredCategories.count, 1)
        XCTAssertEqual(sut.state.filteredCategories.first?.nombre, "Supermercado")
        XCTAssertEqual(sut.state.selectedTransactionType, .gasto)
        XCTAssertFalse(sut.state.isEditing)
    }

    @MainActor
    func testOnTransactionTypeSelected_switchesTypeAndRefilters() async {
        let catIngreso = TestFactory.makeCategoria(nombre: "Salario", tipo: .ingreso)
        let catGasto = TestFactory.makeCategoria(nombre: "Supermercado", tipo: .gasto)
        mockRepository.seed(categorias: [catIngreso, catGasto])

        sut = AddTransactionViewModel(repository: mockRepository)
        await sut.loadForm()

        sut.onTransactionTypeSelected(.ingreso)

        XCTAssertEqual(sut.state.selectedTransactionType, .ingreso)
        XCTAssertEqual(sut.state.filteredCategories.count, 1)
        XCTAssertEqual(sut.state.filteredCategories.first?.nombre, "Salario")
        XCTAssertEqual(sut.state.selectedCategory?.nombre, "Salario")
    }

    @MainActor
    func testSaveTransaction_validData_insertsAndReturnsTrue() async {
        let cat = TestFactory.makeCategoria(nombre: "Supermercado", tipo: .gasto)
        mockRepository.seed(categorias: [cat])

        sut = AddTransactionViewModel(repository: mockRepository)
        await sut.loadForm()

        sut.onAmountChange("150.50")
        sut.onDescriptionChange("Compra semanal")
        sut.onCategorySelected(cat)

        let result = await sut.saveTransaction()

        XCTAssertTrue(result)
        XCTAssertTrue(mockRepository.didInsertTransaccion)
    }

    @MainActor
    func testSaveTransaction_emptyAmount_returnsFalse() async {
        let cat = TestFactory.makeCategoria(nombre: "Supermercado", tipo: .gasto)
        mockRepository.seed(categorias: [cat])

        sut = AddTransactionViewModel(repository: mockRepository)
        await sut.loadForm()

        sut.onAmountChange("")
        sut.onDescriptionChange("Test")
        sut.onCategorySelected(cat)

        let result = await sut.saveTransaction()
        XCTAssertFalse(result)
    }

    @MainActor
    func testSaveTransaction_zeroAmount_returnsFalse() async {
        let cat = TestFactory.makeCategoria(nombre: "Supermercado", tipo: .gasto)
        mockRepository.seed(categorias: [cat])

        sut = AddTransactionViewModel(repository: mockRepository)
        await sut.loadForm()

        sut.onAmountChange("0.00")
        sut.onDescriptionChange("Test")
        sut.onCategorySelected(cat)

        let result = await sut.saveTransaction()
        XCTAssertFalse(result)
    }

    @MainActor
    func testSaveTransaction_emptyDescription_returnsFalse() async {
        let cat = TestFactory.makeCategoria(nombre: "Supermercado", tipo: .gasto)
        mockRepository.seed(categorias: [cat])

        sut = AddTransactionViewModel(repository: mockRepository)
        await sut.loadForm()

        sut.onAmountChange("100")
        sut.onDescriptionChange("   ")
        sut.onCategorySelected(cat)

        let result = await sut.saveTransaction()
        XCTAssertFalse(result)
    }

    @MainActor
    func testSaveTransaction_noCategory_returnsFalse() async {
        mockRepository.seed(categorias: [])

        sut = AddTransactionViewModel(repository: mockRepository)
        await sut.loadForm()

        sut.onAmountChange("100")
        sut.onDescriptionChange("Test")

        let result = await sut.saveTransaction()
        XCTAssertFalse(result)
    }

    @MainActor
    func testOnCurrencySelected_updatesCurrency() async {
        let cat = TestFactory.makeCategoria(nombre: "Test", tipo: .gasto)
        mockRepository.seed(categorias: [cat])

        sut = AddTransactionViewModel(repository: mockRepository)
        await sut.loadForm()

        sut.onCurrencySelected(.USD)

        XCTAssertEqual(sut.state.selectedCurrency, .USD)
    }

    @MainActor
    func testPendingStatusChange_clearsCompletionDateWhenOff() async {
        let cat = TestFactory.makeCategoria(nombre: "Test", tipo: .gasto)
        mockRepository.seed(categorias: [cat])

        sut = AddTransactionViewModel(repository: mockRepository)
        await sut.loadForm()

        sut.onPendingStatusChange(true)
        XCTAssertTrue(sut.state.isPending)

        sut.onCompletionDateChange(Date().addingTimeInterval(86400))
        XCTAssertNotNil(sut.state.completionDate)

        sut.onPendingStatusChange(false)
        XCTAssertFalse(sut.state.isPending)
        XCTAssertNil(sut.state.completionDate)
    }

    @MainActor
    func testEditMode_loadsExistingTransaction() async {
        let cat = TestFactory.makeCategoria(nombre: "Supermercado", tipo: .gasto)
        let existingTx = TestFactory.makeTransaccion(
            monto: 200.0,
            moneda: .USD,
            descripcion: "Compra editada",
            tipo: .gasto,
            categoria: cat
        )
        mockRepository.seed(transacciones: [existingTx])
        mockRepository.seed(categorias: [cat])

        sut = AddTransactionViewModel(repository: mockRepository, transactionId: existingTx.id)
        await sut.loadForm()

        XCTAssertTrue(sut.state.isEditing)
        XCTAssertEqual(sut.state.amount, "200.00")
        XCTAssertEqual(sut.state.description, "Compra editada")
        XCTAssertEqual(sut.state.selectedCurrency, .USD)
        XCTAssertEqual(sut.state.selectedCategory?.id, cat.id)
    }
}
