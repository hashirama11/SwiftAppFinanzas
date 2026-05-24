import Foundation

struct AddTransactionState {
    var allCategories: [Categoria] = []
    var filteredCategories: [Categoria] = []
    var selectedCategory: Categoria? = nil
    var selectedTransactionType: TipoTransaccion = .gasto
    var amount: String = ""
    var description: String = ""
    var isEditing: Bool = false
    var transactionDate: Date? = nil
    var selectedCurrency: Moneda = .VES
    var isPending: Bool = false
    var completionDate: Date? = nil
}
