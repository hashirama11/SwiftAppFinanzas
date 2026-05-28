import Foundation

struct AllTransactionsState {
    var transactions: [TransactionWithDetails] = []
    var isLoading: Bool = true
    var isLoadingMore: Bool = false
    var searchQuery: String = ""
    var filterType: TipoTransaccion? = nil
    var hasMorePages: Bool = true
    var currentOffset: Int = 0
    var totalCount: Int = 0
    let pageSize: Int = 20
}
