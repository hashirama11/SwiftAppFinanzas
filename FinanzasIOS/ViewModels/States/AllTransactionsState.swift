import Foundation

struct AllTransactionsState {
    var allTransactions: [TransactionWithDetails] = []
    var filteredTransactions: [TransactionWithDetails] = []
    var isLoading: Bool = true
    var searchQuery: String = ""
    var filterType: TipoTransaccion? = nil
}
