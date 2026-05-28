import SwiftUI
import SwiftData

struct BudgetCategoryPickerView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    let mes: Int
    let anho: Int
    var onSelect: (UUID) -> Void
    let onBack: () -> Void

    @State private var categorias: [Categoria] = []
    @State private var isLoading = true

    var categoriasGasto: [Categoria] {
        categorias.filter { $0.tipoEnum == .gasto }.sorted { $0.nombre < $1.nombre }
    }

    var categoriasIngreso: [Categoria] {
        categorias.filter { $0.tipoEnum == .ingreso }.sorted { $0.nombre < $1.nombre }
    }

    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    theme.colors.background.ignoresSafeArea()
                    ProgressView().tint(theme.colors.primary).scaleEffect(1.2)
                }
            } else {
                pickerContent
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Seleccionar categoría")
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
        .task { await cargar() }
    }

    private var pickerContent: some View {
        List {
            if !categoriasGasto.isEmpty {
                Section {
                    ForEach(categoriasGasto) { cat in
                        categoriaRow(cat)
                    }
                } header: {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(theme.colors.accentRed)
                        Text("Gastos")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.colors.textSecondary)
                            .textCase(.uppercase)
                    }
                }
            }

            if !categoriasIngreso.isEmpty {
                Section {
                    ForEach(categoriasIngreso) { cat in
                        categoriaRow(cat)
                    }
                } header: {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(theme.colors.accentGreen)
                        Text("Ingresos")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.colors.textSecondary)
                            .textCase(.uppercase)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollIndicators(.hidden)
    }

    private func categoriaRow(_ cat: Categoria) -> some View {
        Button {
            onSelect(cat.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: cat.iconoEnum.sfSymbol)
                    .font(.system(size: 18))
                    .foregroundColor(cat.tipoEnum == .ingreso ? theme.colors.accentGreen : theme.colors.accentRed)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(cat.nombre)
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(theme.colors.textPrimary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.vertical, 4)
        }
    }

    private func cargar() async {
        let repo = FinanzasRepositoryImpl(modelContext: modelContext)
        if let cats = try? await repo.getAllCategorias() {
            categorias = cats
        }
        isLoading = false
    }
}
