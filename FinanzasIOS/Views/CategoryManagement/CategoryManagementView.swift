import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    let onBack: () -> Void

    @State private var viewModel: CategoryManagementViewModel?
    @State private var showSheet: Bool = false
    @State private var editingCategory: Categoria?

    @State private var categoryName: String = ""
    @State private var categoryType: TipoTransaccion = .gasto
    @State private var categoryIcon: IconosEstandar = .otros

    @State private var showDeleteConfirmation: Bool = false
    @State private var categoryToDelete: Categoria?

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
        .enableBackGesture()
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
        .sheet(isPresented: $showSheet) {
            categoryFormSheet
        }
        .alert("Eliminar Categoría", isPresented: $showDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { categoryToDelete = nil }
            Button("Eliminar", role: .destructive) {
                if let cat = categoryToDelete {
                    Task { await viewModel?.deleteCategory(cat) }
                }
                categoryToDelete = nil
            }
        } message: {
            if let cat = categoryToDelete {
                Text("¿Estás seguro de que deseas eliminar la categoría '\(cat.nombre)'? Las transacciones asociadas no se eliminarán.")
            }
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
                        Button {
                            openEditSheet(for: categoria)
                        } label: {
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

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                categoryToDelete = categoria
                                showDeleteConfirmation = true
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }

                            Button {
                                openEditSheet(for: categoria)
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                            .tint(theme.colors.primary)
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
            openAddSheet()
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

    private var categoryFormSheet: some View {
        NavigationStack {
            Form {
                Section("Nombre") {
                    TextField("Nombre de la categoría", text: $categoryName)
                }

                Section("Tipo") {
                    Picker("Tipo", selection: $categoryType) {
                        ForEach(TipoTransaccion.allCases, id: \.self) { tipo in
                            Text(tipo.nombre).tag(tipo)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Icono") {
                    Picker("Icono", selection: $categoryIcon) {
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
                            if let editingCat = editingCategory {
                                await viewModel?.updateCategory(
                                    editingCat,
                                    name: categoryName,
                                    type: categoryType,
                                    icon: categoryIcon
                                )
                            } else {
                                await viewModel?.addCategory(
                                    name: categoryName,
                                    type: categoryType,
                                    icon: categoryIcon
                                )
                            }
                            showSheet = false
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text(editingCategory == nil ? "Guardar Categoría" : "Actualizar Categoría")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if editingCategory != nil {
                    Section {
                        Button(role: .destructive) {
                            categoryToDelete = editingCategory
                            showSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showDeleteConfirmation = true
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Eliminar Categoría")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(editingCategory == nil ? "Nueva Categoría" : "Editar Categoría")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancelar") { showSheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func openAddSheet() {
        editingCategory = nil
        categoryName = ""
        categoryType = .gasto
        categoryIcon = .otros
        showSheet = true
    }

    private func openEditSheet(for categoria: Categoria) {
        editingCategory = categoria
        categoryName = categoria.nombre
        categoryType = categoria.tipoEnum
        categoryIcon = categoria.iconoEnum
        showSheet = true
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
