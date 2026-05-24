import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    let onBack: () -> Void

    @State private var viewModel: CategoryManagementViewModel?
    @State private var showAddDialog: Bool = false

    @State private var newCategoryName: String = ""
    @State private var newCategoryType: TipoTransaccion = .gasto
    @State private var newCategoryIcon: IconosEstandar = .otros

    var body: some View {
        Group {
            if let vm = viewModel {
                categoryContent(vm: vm)
            } else {
                loadingView
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Mis Categorías")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.body.weight(.semibold))
                        Text("Atrás")
                    }
                    .foregroundColor(theme.colors.primary)
                }
            }
        }
        .sheet(isPresented: $showAddDialog) {
            addCategorySheet
        }
        .task {
            await setupViewModel()
        }
    }

    @ViewBuilder
    private func categoryContent(vm: CategoryManagementViewModel) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if vm.categories.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(vm.categories) { categoria in
                        HStack(spacing: 12) {
                            Image(systemName: categoria.iconoEnum.sfSymbol)
                                .font(.system(size: 18))
                                .foregroundColor(
                                    categoria.tipoEnum == .ingreso
                                        ? theme.colors.accentGreen
                                        : theme.colors.accentRed
                                )
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(categoria.nombre)
                                    .font(theme.typography.bodyLarge)
                                    .foregroundColor(theme.colors.textPrimary)
                                Text(categoria.tipoEnum.nombre)
                                    .font(theme.typography.labelSmall)
                                    .foregroundColor(theme.colors.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        let idsToDelete = indexSet.map { vm.categories[$0].id }
                        for id in idsToDelete {
                            Task { await vm.deleteCategory(by: id) }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden)
            }

            fabButton
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag.slash.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.textSecondary.opacity(0.4))

            Text("Sin categorías personalizadas")
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textSecondary)

            Text("Toca + para crear tu primera categoría")
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.textSecondary.opacity(0.7))
        }
    }

    private var fabButton: some View {
        Button {
            newCategoryName = ""
            newCategoryType = .gasto
            newCategoryIcon = .otros
            showAddDialog = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.colors.primary, theme.colors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: theme.colors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                )
        }
        .padding(.trailing, 20)
        .padding(.bottom, 16)
    }

    private var addCategorySheet: some View {
        NavigationStack {
            Form {
                Section("Nombre") {
                    TextField("Nombre de la categoría", text: $newCategoryName)
                }

                Section("Tipo") {
                    Picker("Tipo", selection: $newCategoryType) {
                        ForEach(TipoTransaccion.allCases, id: \.self) { tipo in
                            Text(tipo.nombre).tag(tipo)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Icono") {
                    Picker("Icono", selection: $newCategoryIcon) {
                        ForEach(IconosEstandar.allCases, id: \.self) { icono in
                            HStack {
                                Image(systemName: icono.sfSymbol)
                                    .foregroundColor(theme.colors.primary)
                                Text(icono.nombreLegible)
                            }
                            .tag(icono)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section {
                    Button {
                        Task {
                            await viewModel?.addCategory(
                                name: newCategoryName,
                                type: newCategoryType,
                                icon: newCategoryIcon
                            )
                            showAddDialog = false
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Guardar Categoría")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Nueva Categoría")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancelar") { showAddDialog = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func setupViewModel() async {
        let repo = FinanzasRepositoryImpl(modelContext: modelContext)
        let vm = CategoryManagementViewModel(repository: repo)
        await vm.loadCategories()
        viewModel = vm
    }

    private var loadingView: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            ProgressView().tint(theme.colors.primary).scaleEffect(1.2)
        }
    }
}
