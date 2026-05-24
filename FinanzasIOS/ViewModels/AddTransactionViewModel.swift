import Foundation
import Observation

@Observable
final class AddTransactionViewModel {
    var state = AddTransactionState()

    private let repository: FinanzasRepository
    private var editingTransactionId: UUID?

    init(repository: FinanzasRepository, transactionId: UUID? = nil) {
        self.repository = repository
        self.editingTransactionId = transactionId
    }

    func loadForm() async {
        guard let categorias = try? await repository.getAllCategorias() else { return }
        state.allCategories = categorias

        if let transactionId = editingTransactionId,
           let transaccion = try? await repository.getTransaccion(by: transactionId) {
            state.isEditing = true
            state.selectedTransactionType = transaccion.tipoEnum
            state.amount = String(format: "%.2f", transaccion.monto)
            state.description = transaccion.descripcion
            state.selectedCurrency = transaccion.monedaEnum
            state.transactionDate = transaccion.fecha
            state.isPending = transaccion.isPending
            state.completionDate = transaccion.fechaConcrecion
            state.selectedCategory = transaccion.categoria
            filterCategories()
        } else {
            filterCategories()
        }
    }

    func onTransactionTypeSelected(_ type: TipoTransaccion) {
        state.selectedTransactionType = type
        filterCategories()
    }

    func onCurrencySelected(_ currency: Moneda) {
        state.selectedCurrency = currency
    }

    func onAmountChange(_ amount: String) {
        state.amount = amount
    }

    func onDescriptionChange(_ description: String) {
        state.description = description
    }

    func onCategorySelected(_ categoria: Categoria) {
        state.selectedCategory = categoria
    }

    func onPendingStatusChange(_ isPending: Bool) {
        state.isPending = isPending
        if !isPending {
            state.completionDate = nil
        }
    }

    func onCompletionDateChange(_ date: Date) {
        state.completionDate = date
    }

    func saveTransaction() async -> Bool {
        guard let amountValue = Double(state.amount.replacingOccurrences(of: ",", with: ".")),
              amountValue > 0,
              !state.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              state.selectedCategory != nil else {
            return false
        }

        let estado: EstadoTransaccion = state.isPending ? .pendiente : .concretado

        if state.isEditing, let id = editingTransactionId,
           let existing = try? await repository.getTransaccion(by: id) {
            existing.monto = amountValue
            existing.monedaEnum = state.selectedCurrency
            existing.descripcion = state.description
            existing.tipoEnum = state.selectedTransactionType
            existing.estadoEnum = estado
            existing.categoria = state.selectedCategory
            existing.fechaConcrecion = state.isPending ? state.completionDate : nil

            try? await repository.updateTransaccion(existing)

            if state.isPending, state.completionDate != nil {
                await NotificationManager.shared.scheduleNotification(for: existing)
            } else {
                NotificationManager.shared.cancelNotification(for: existing)
            }
        } else {
            let transaccion = Transaccion(
                monto: amountValue,
                moneda: state.selectedCurrency,
                descripcion: state.description,
                fecha: Date(),
                tipo: state.selectedTransactionType,
                estado: estado,
                categoria: state.selectedCategory,
                fechaConcrecion: state.isPending ? state.completionDate : nil
            )

            try? await repository.insertTransaccion(transaccion)

            if state.isPending, state.completionDate != nil {
                await NotificationManager.shared.scheduleNotification(for: transaccion)
            }
        }

        await MainActor.run {
            NotificationCenter.default.post(name: .transactionDidChange, object: nil)
        }
        return true
    }

    private func filterCategories() {
        state.filteredCategories = state.allCategories.filter {
            $0.tipoEnum == state.selectedTransactionType
        }
        if state.selectedCategory == nil || state.selectedCategory?.tipoEnum != state.selectedTransactionType {
            state.selectedCategory = state.filteredCategories.first
        }
    }
}
