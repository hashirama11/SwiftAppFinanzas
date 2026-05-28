import SwiftUI
import SwiftData

struct SetBudgetView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let categoriaId: UUID
    let mes: Int
    let anho: Int
    var onSaved: (() -> Void)?

    @State private var categoria: Categoria?
    @State private var montoTexto: String = ""
    @State private var monedaSeleccionada: Moneda = .VES
    @State private var aplicarMesesSiguientes: Bool = true
    @State private var presupuestoActual: PresupuestoCategoria?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showError: Bool = false

    private var esEdicion: Bool { presupuestoActual != nil }

    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    theme.colors.background.ignoresSafeArea()
                    ProgressView().tint(theme.colors.primary).scaleEffect(1.2)
                }
            } else {
                formulario
            }
        }
        .background(theme.colors.background)
        .navigationTitle(categoria?.nombre ?? "Presupuesto")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancelar") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Guardar") { Task { await guardar() } }
                    .fontWeight(.semibold)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .task { await cargar() }
    }

    private var formulario: some View {
        Form {
            if let cat = categoria {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: cat.iconoEnum.sfSymbol)
                            .font(.system(size: 28))
                            .foregroundColor(cat.tipoEnum == .ingreso ? theme.colors.accentGreen : theme.colors.accentRed)
                            .frame(width: 44, height: 44)
                            .background(theme.colors.surfaceSecondary)
                            .cornerRadius(theme.shapes.medium)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(cat.nombre)
                                    .font(theme.typography.titleMedium)
                                    .foregroundColor(theme.colors.textPrimary)
                                Spacer()
                            }
                            Text(cat.tipoEnum == .ingreso ? "Categoría de ingreso" : "Categoría de gasto")
                                .font(theme.typography.labelSmall)
                                .foregroundColor(theme.colors.textSecondary)
                            Text("Mes: \(nombreMes(mes)) \(String(anho))")
                                .font(theme.typography.labelSmall)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                }

                Section("Presupuesto mensual") {
                    Picker("Moneda", selection: $monedaSeleccionada) {
                        ForEach(Moneda.allCases, id: \.self) { m in
                            Text("\(m.nombre) (\(m.simbolo))").tag(m)
                        }
                    }

                    HStack {
                        Text(monedaSeleccionada.simbolo)
                            .foregroundColor(theme.colors.textSecondary)
                            .font(theme.typography.bodyLarge)
                        TextField("0,00", text: $montoTexto)
                            .keyboardType(.decimalPad)
                            .font(theme.typography.bodyLarge)
                    }
                }

                if !esEdicion {
                    Section {
                        Toggle("Aplicar a los meses siguientes", isOn: $aplicarMesesSiguientes)
                            .tint(theme.colors.primary)
                    } footer: {
                        Text("El presupuesto se copiará desde \(nombreMes(mes)) \(String(anho)) a los 11 meses siguientes. Podrás editar cualquier mes individualmente después.")
                    }
                } else {
                    Section {
                        Text("Editando el presupuesto de \(nombreMes(mes)) \(String(anho)). Los meses anteriores no se modificarán.")
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                if esEdicion {
                    Section {
                        Button(role: .destructive) {
                            Task {
                                await eliminar()
                                onSaved?()
                                NotificationCenter.default.post(name: .budgetDidChange, object: nil)
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Quitar presupuesto")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }

    private func cargar() async {
        let repo = FinanzasRepositoryImpl(modelContext: modelContext)

        do {
            let cats = try await repo.getAllCategorias()
            categoria = cats.first { $0.id == categoriaId }
        } catch {
            errorMessage = "Error al cargar categoría: \(error.localizedDescription)"
            isLoading = false
            return
        }

        do {
            if let existing = try await repo.getPresupuesto(categoriaId: categoriaId, mes: mes, anho: anho) {
                presupuestoActual = existing
                montoTexto = String(format: "%.2f", existing.monto)
                monedaSeleccionada = existing.monedaEnum
                aplicarMesesSiguientes = false
            } else {
                montoTexto = ""
                monedaSeleccionada = .VES
                aplicarMesesSiguientes = true
            }
        } catch {
            errorMessage = "Error al cargar presupuesto: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func guardar() async {
        let repo = FinanzasRepositoryImpl(modelContext: modelContext)
        let monto = Double(montoTexto.replacingOccurrences(of: ",", with: ".")) ?? 0

        guard monto > 0 else {
            errorMessage = "Ingresa un monto mayor a 0"
            showError = true
            return
        }

        let calendar = Calendar.current

        if aplicarMesesSiguientes && !esEdicion {
            var components = DateComponents()
            components.year = anho
            components.month = mes
            components.day = 1
            guard let baseDate = calendar.date(from: components) else {
                errorMessage = "Fecha inválida"
                showError = true
                return
            }

            for offset in 0..<12 {
                guard let targetDate = calendar.date(byAdding: .month, value: offset, to: baseDate) else { continue }
                let targetMes = calendar.component(.month, from: targetDate)
                let targetAnho = calendar.component(.year, from: targetDate)

                let presupuesto = PresupuestoCategoria(
                    categoria: categoria,
                    mes: targetMes,
                    anho: targetAnho,
                    monto: monto,
                    moneda: monedaSeleccionada,
                    esRecurrente: true
                )
                do {
                    try await repo.upsertPresupuesto(presupuesto)
                } catch {
                    errorMessage = "Error al guardar: \(error.localizedDescription)"
                    showError = true
                    return
                }
            }
        } else {
            let presupuesto = PresupuestoCategoria(
                categoria: categoria,
                mes: mes,
                anho: anho,
                monto: monto,
                moneda: monedaSeleccionada
            )
            do {
                try await repo.upsertPresupuesto(presupuesto)
            } catch {
                errorMessage = "Error al guardar: \(error.localizedDescription)"
                showError = true
                return
            }
        }

        NotificationCenter.default.post(name: .budgetDidChange, object: nil)
        onSaved?()
    }

    private func eliminar() async {
        guard let existing = presupuestoActual else { return }
        let repo = FinanzasRepositoryImpl(modelContext: modelContext)
        do {
            try await repo.deletePresupuesto(existing)
        } catch {
            errorMessage = "Error al eliminar: \(error.localizedDescription)"
        }
    }

    private func nombreMes(_ m: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        let index = m - 1
        if index >= 0, index < formatter.monthSymbols.count {
            return formatter.monthSymbols[index].capitalized
        }
        return ""
    }
}
