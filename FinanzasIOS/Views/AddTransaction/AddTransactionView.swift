import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    let transactionId: UUID?
    let onBack: () -> Void

    @State private var viewModel: AddTransactionViewModel?
    @State private var showCategoryPicker: Bool = false

    var body: some View {
        Group {
            if let vm = viewModel {
                formContent(vm: vm)
            } else {
                loadingView
            }
        }
        .background(theme.colors.background)
        .navigationTitle(transactionId == nil ? "Nueva Transacción" : "Editar Transacción")
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

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    // Desenvolvemos el viewModel de forma segura al presionar el botón
                    if let vmSeguro = viewModel {
                        Task { await performSave(vmSeguro) }
                    }
                }) {
                    Text(transactionId == nil ? "Guardar" : "Actualizar")
                        .font(.body.weight(.semibold))
                        .foregroundColor(theme.colors.primary)
                }
                // Opcional y recomendado: Deshabilita el botón mientras la vista carga
                .disabled(viewModel == nil)
            }
        }
        .task {
            await setupViewModel()
        }
    }

    @ViewBuilder
    private func formContent(vm: AddTransactionViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                transactionTypeSection(vm: vm)
                currencySection(vm: vm)
                detailsSection(vm: vm)
                categorySection(vm: vm)
                pendingSection(vm: vm)
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
    }

    private func transactionTypeSection(vm: AddTransactionViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Tipo de transacción")

            HStack(spacing: 0) {
                ForEach(TipoTransaccion.allCases, id: \.self) { tipo in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            vm.onTransactionTypeSelected(tipo)
                        }
                    } label: {
                        Text(tipo == .ingreso ? "Ingreso" : "Gasto")
                            .font(theme.typography.bodyLarge)
                            .fontWeight(vm.state.selectedTransactionType == tipo ? .semibold : .regular)
                            .foregroundColor(
                                vm.state.selectedTransactionType == tipo
                                    ? .white
                                    : theme.colors.textPrimary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                vm.state.selectedTransactionType == tipo
                                    ? (tipo == .ingreso ? theme.colors.accentGreen : theme.colors.accentRed)
                                    : theme.colors.surfaceSecondary
                            )
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.shapes.small))
            .overlay(
                RoundedRectangle(cornerRadius: theme.shapes.small)
                    .stroke(theme.colors.divider, lineWidth: 0.5)
            )
        }
    }

    private func currencySection(vm: AddTransactionViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Moneda")

            HStack(spacing: 0) {
                ForEach(Moneda.allCases, id: \.self) { moneda in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            vm.onCurrencySelected(moneda)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(moneda.simbolo)
                                .font(theme.typography.titleLarge)
                                .fontWeight(.semibold)
                            Text(moneda.nombre)
                                .font(theme.typography.labelSmall)
                        }
                        .foregroundColor(
                            vm.state.selectedCurrency == moneda
                                ? theme.colors.primary
                                : theme.colors.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            vm.state.selectedCurrency == moneda
                                ? theme.colors.primary.opacity(0.08)
                                : Color.clear
                        )
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.shapes.small))
            .overlay(
                RoundedRectangle(cornerRadius: theme.shapes.small)
                    .stroke(theme.colors.divider, lineWidth: 0.5)
            )
        }
    }

    private func detailsSection(vm: AddTransactionViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Detalles")

            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    Text(vm.state.selectedCurrency.simbolo)
                        .font(theme.typography.titleLarge)
                        .foregroundColor(theme.colors.textSecondary)

                    TextField("0.00", text: Binding(
                        get: { vm.state.amount },
                        set: { vm.onAmountChange($0) }
                    ))
                    .keyboardType(.decimalPad)
                    .font(theme.typography.titleLarge)
                    .foregroundColor(theme.colors.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(theme.colors.surfaceSecondary)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: theme.shapes.small,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: theme.shapes.small
                    )
                )

                Divider()
                    .padding(.leading, 16)

                TextField("Descripción (opcional)", text: Binding(
                    get: { vm.state.description },
                    set: { vm.onDescriptionChange($0) }
                ))
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(theme.colors.surfaceSecondary)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: theme.shapes.small,
                        bottomTrailingRadius: theme.shapes.small,
                        topTrailingRadius: 0
                    )
                )
            }
            .overlay(
                RoundedRectangle(cornerRadius: theme.shapes.small)
                    .stroke(theme.colors.divider, lineWidth: 0.5)
            )
        }
    }

    private func categorySection(vm: AddTransactionViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Categoría")

            Button {
                showCategoryPicker = true
            } label: {
                HStack {
                    if let cat = vm.state.selectedCategory {
                        Image(systemName: cat.iconoEnum.sfSymbol)
                            .font(.system(size: 16))
                            .foregroundColor(theme.colors.primary)
                        Text(cat.nombre)
                            .font(theme.typography.bodyLarge)
                            .foregroundColor(theme.colors.textPrimary)
                    } else {
                        Text("Seleccionar categoría")
                            .font(theme.typography.bodyLarge)
                            .foregroundColor(theme.colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(theme.colors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: theme.shapes.small))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.shapes.small)
                        .stroke(theme.colors.divider, lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showCategoryPicker) {
            categoryPickerSheet(vm: vm)
        }
    }

    private func categoryPickerSheet(vm: AddTransactionViewModel) -> some View {
        NavigationStack {
            List(vm.state.filteredCategories) { cat in
                Button {
                    vm.onCategorySelected(cat)
                    showCategoryPicker = false
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: cat.iconoEnum.sfSymbol)
                            .font(.system(size: 18))
                            .foregroundColor(theme.colors.primary)
                            .frame(width: 28)

                        Text(cat.nombre)
                            .font(theme.typography.bodyLarge)
                            .foregroundColor(theme.colors.textPrimary)

                        Spacer()

                        if cat.id == vm.state.selectedCategory?.id {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                                .foregroundColor(theme.colors.primary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Seleccionar Categoría")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        showCategoryPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func pendingSection(vm: AddTransactionViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Recordatorio")

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Marcar como pendiente")
                            .font(theme.typography.bodyLarge)
                            .foregroundColor(theme.colors.textPrimary)
                        Text("Programa un recordatorio futuro")
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { vm.state.isPending },
                        set: { newValue in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                vm.onPendingStatusChange(newValue)
                            }
                        }
                    ))
                    .tint(theme.colors.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if vm.state.isPending {
                    Divider()
                        .padding(.leading, 16)

                    DatePicker(
                        "Fecha de recordatorio",
                        selection: Binding(
                            get: { vm.state.completionDate ?? Date().addingTimeInterval(86400) },
                            set: { vm.onCompletionDateChange($0) }
                        ),
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .padding(12)
                    .tint(theme.colors.primary)
                }
            }
            .background(theme.colors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: theme.shapes.small))
            .overlay(
                RoundedRectangle(cornerRadius: theme.shapes.small)
                    .stroke(theme.colors.divider, lineWidth: 0.5)
            )
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(theme.typography.labelMedium)
            .foregroundColor(theme.colors.textSecondary)
            .textCase(.uppercase)
    }

    private func performSave(_ vm: AddTransactionViewModel) async {
        let success = await vm.saveTransaction()
        if success {
            onBack()
        }
    }

    private func setupViewModel() async {
        let repo = FinanzasRepositoryImpl(modelContext: modelContext)
        let vm = AddTransactionViewModel(
            repository: repo,
            transactionId: transactionId
        )
        await vm.loadForm()
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
