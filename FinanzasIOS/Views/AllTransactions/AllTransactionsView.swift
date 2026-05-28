import SwiftUI
import SwiftData

struct AllTransactionsView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    let onBack: () -> Void
    let onTransactionClick: (UUID) -> Void

    @State private var viewModel: AllTransactionsViewModel?
    @State private var searchText: String = ""

    var body: some View {
        Group {
            if let vm = viewModel {
                contentView(vm: vm)
            } else {
                loadingView
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Historial")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .enableBackGesture()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("Atrás")
                    }
                    .foregroundColor(theme.colors.primary)
                }
            }
        }
        .task {
            await setupViewModel()
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .transactionDidChange) {
                await viewModel?.loadInitialData()
            }
        }
    }

    @ViewBuilder
    private func contentView(vm: AllTransactionsViewModel) -> some View {
        VStack(spacing: 0) {
            searchAndFilterBar(vm: vm)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            if vm.state.transactions.isEmpty && !vm.state.isLoading {
                emptyState
            } else {
                transactionsList(vm: vm)
            }
        }
    }

    private func searchAndFilterBar(vm: AllTransactionsViewModel) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.colors.textSecondary)
                TextField("Buscar...", text: $searchText)
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textPrimary)
                    .onChange(of: searchText) { _, newValue in
                        vm.onSearchQueryChange(newValue)
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        vm.onSearchQueryChange("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(theme.colors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: theme.shapes.small))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: "Todos", isSelected: vm.state.filterType == nil) {
                        vm.onFilterTypeChange(nil)
                    }
                    ForEach(TipoTransaccion.allCases, id: \.self) { tipo in
                        filterChip(title: tipo.nombre, isSelected: vm.state.filterType == tipo) {
                            vm.onFilterTypeChange(tipo)
                        }
                    }
                }
            }
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.labelMedium)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : theme.colors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? theme.colors.primary : theme.colors.surfaceSecondary)
                )
        }
    }

    private func transactionsList(vm: AllTransactionsViewModel) -> some View {
        List {
            ForEach(vm.state.transactions) { tx in
                TransactionItem(transaction: tx) {
                    onTransactionClick(tx.transaccion.id)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await vm.deleteTransaction(tx) }
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
            }

            if vm.state.hasMorePages || vm.state.isLoadingMore {
                Section {
                    HStack {
                        Spacer()
                        if vm.state.isLoadingMore {
                            ProgressView()
                                .tint(theme.colors.primary)
                                .scaleEffect(0.9)
                        } else {
                            Button {
                                Task { await vm.loadMore() }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.down.circle")
                                        .font(.system(size: 14))
                                    Text("Cargar más")
                                        .font(theme.typography.bodyMedium)
                                }
                                .foregroundColor(theme.colors.primary)
                                .padding(.vertical, 8)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }

            if !vm.state.transactions.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        Text("\(vm.state.currentOffset) de \(vm.state.totalCount) transacciones")
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.colors.textSecondary)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(theme.colors.textSecondary.opacity(0.4))

            Text("Sin resultados")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)

            Text("No se encontraron transacciones con los filtros actuales")
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }

    private func setupViewModel() async {
        let repo = FinanzasRepositoryImpl(modelContext: modelContext)
        let vm = AllTransactionsViewModel(repository: repo)
        await vm.loadInitialData()
        viewModel = vm
    }

    private var loadingView: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            ProgressView()
                .tint(theme.colors.primary)
                .scaleEffect(1.2)
        }
    }
}
