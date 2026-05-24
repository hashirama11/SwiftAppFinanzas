import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    let transactionId: UUID
    let onBack: () -> Void
    let onEditClick: (UUID) -> Void

    @State private var viewModel: TransactionDetailViewModel?
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        Group {
            if let vm = viewModel {
                detailContent(vm: vm)
            } else {
                loadingView
            }
        }
        .background(theme.colors.background)
        .navigationBarBackButtonHidden()
        .enableBackGesture()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(theme.colors.primary)
                }
            }
        }
        .task {
            await setupViewModel()
        }
        .alert("Eliminar Transacción", isPresented: $showDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                Task {
                    await viewModel?.deleteTransaction()
                    onBack()
                }
            }
        } message: {
            Text("¿Estás seguro de que deseas eliminar esta transacción? Esta acción no se puede deshacer.")
        }
    }

    @ViewBuilder
    private func detailContent(vm: TransactionDetailViewModel) -> some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    transactionHeader(vm: vm)

                    if let tx = vm.transactionWithDetails {
                        transactionDetailsCard(tx: tx)
                    }

                    HStack(spacing: 16) {
                        placeholderButton(
                            title: "Editar",
                            icon: "pencil",
                            action: { onEditClick(transactionId) }
                        )

                        placeholderButton(
                            title: "Eliminar",
                            icon: "trash",
                            isDestructive: true,
                            action: { showDeleteConfirmation = true }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func transactionHeader(vm: TransactionDetailViewModel) -> some View {
        VStack(spacing: 8) {
            if let tx = vm.transactionWithDetails {
                Image(systemName: tx.categoria?.iconoEnum.sfSymbol ?? "questionmark.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.colors.primary, theme.colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(tx.transaccion.descripcion)
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(tx.categoria?.nombre ?? "Sin categoría")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            } else {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.colors.primary, theme.colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Detalle")
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.colors.textPrimary)

                Text("Información de la transacción")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
    }

    private func transactionDetailsCard(tx: TransactionWithDetails) -> some View {
        VStack(spacing: 0) {
            detailRow(label: "Monto", value: {
                let prefix = tx.transaccion.tipoEnum == .ingreso ? "+" : "-"
                let formatted = Formatters.currency.string(from: NSNumber(value: tx.transaccion.monto)) ?? String(format: "%.2f", tx.transaccion.monto)
                return "\(prefix)\(tx.transaccion.monedaEnum.simbolo) \(formatted)"
            }(), color: tx.transaccion.tipoEnum == .ingreso ? theme.colors.accentGreen : theme.colors.accentRed)

            Divider().padding(.leading, 16)

            detailRow(label: "Tipo", value: tx.transaccion.tipoEnum == .ingreso ? "Ingreso" : "Gasto")

            Divider().padding(.leading, 16)

            detailRow(label: "Moneda", value: tx.transaccion.monedaEnum.nombre)

            Divider().padding(.leading, 16)

            detailRow(label: "Fecha", value: Formatters.formatDate(tx.transaccion.fecha))

            if tx.transaccion.isPending, let fechaConcrecion = tx.transaccion.fechaConcrecion {
                Divider().padding(.leading, 16)
                detailRow(label: "Recordatorio", value: Formatters.formatDate(fechaConcrecion))
            }

            Divider().padding(.leading, 16)

            detailRow(
                label: "Estado",
                value: tx.transaccion.isPending ? "Pendiente" : "Concretado",
                color: tx.transaccion.isPending ? theme.colors.accentRed : theme.colors.accentGreen
            )
        }
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.shapes.medium))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private func detailRow(label: String, value: String, color: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textSecondary)
            Spacer()
            Text(value)
                .font(theme.typography.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(color ?? theme.colors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func placeholderButton(
        title: String,
        icon: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(theme.typography.labelMedium)
                .foregroundColor(isDestructive ? theme.colors.accentRed : theme.colors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: theme.shapes.pill)
                        .fill(
                            isDestructive
                                ? theme.colors.accentRed.opacity(0.12)
                                : theme.colors.primary.opacity(0.12)
                        )
                )
        }
    }

    private func setupViewModel() async {
        let repo = FinanzasRepositoryImpl(modelContext: modelContext)
        let vm = TransactionDetailViewModel(repository: repo, transactionId: transactionId)
        await vm.loadTransaction()
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
