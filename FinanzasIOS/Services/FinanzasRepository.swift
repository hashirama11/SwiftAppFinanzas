import Foundation
import SwiftData

@MainActor
protocol FinanzasRepository: Sendable {
    func getAllTransacciones() async throws -> [Transaccion]
    func getTransaccionesPaginadas(limit: Int, offset: Int, tipo: String?, filtroTexto: String?) async throws -> [Transaccion]
    func getTransaccionesCount(tipo: String?) async throws -> Int
    func insertTransaccion(_ transaccion: Transaccion) async throws
    func updateTransaccion(_ transaccion: Transaccion) async throws
    func deleteTransaccion(_ transaccion: Transaccion) async throws
    func deleteTransaccion(by id: UUID) async throws
    func getTransaccion(by id: UUID) async throws -> Transaccion?

    func getAllCategorias() async throws -> [Categoria]
    func insertCategoria(_ categoria: Categoria) async throws
    func updateCategoria(_ categoria: Categoria) async throws
    func deleteCategoria(_ categoria: Categoria) async throws

    func getUsuario() async throws -> Usuario?
    func upsertUsuario(_ usuario: Usuario) async throws

    func getPresupuestos(mes: Int, anho: Int) async throws -> [PresupuestoCategoria]
    func getPresupuesto(categoriaId: UUID, mes: Int, anho: Int) async throws -> PresupuestoCategoria?
    func upsertPresupuesto(_ presupuesto: PresupuestoCategoria) async throws
    func deletePresupuesto(_ presupuesto: PresupuestoCategoria) async throws

    func getAllMesesCerrados() async throws -> [MesCerrado]
    func getMesCerrado(mes: Int, anho: Int) async throws -> MesCerrado?
}

@MainActor
final class FinanzasRepositoryImpl: FinanzasRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAllTransacciones() async throws -> [Transaccion] {
        let descriptor = FetchDescriptor<Transaccion>(
            sortBy: [SortDescriptor(\.fecha, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getTransaccionesPaginadas(limit: Int, offset: Int, tipo: String?, filtroTexto: String?) async throws -> [Transaccion] {
        let all = try await getAllTransacciones()

        var filtered = all
        if let tipo = tipo {
            filtered = filtered.filter { $0.tipo == tipo }
        }
        if let texto = filtroTexto, !texto.isEmpty {
            filtered = filtered.filter {
                $0.descripcion.localizedCaseInsensitiveContains(texto) ||
                ($0.categoria?.nombre ?? "").localizedCaseInsensitiveContains(texto)
            }
        }

        let start = min(offset, filtered.count)
        let end = min(offset + limit, filtered.count)
        guard start < end else { return [] }
        return Array(filtered[start..<end])
    }

    func getTransaccionesCount(tipo: String?) async throws -> Int {
        let all = try await getAllTransacciones()
        if let tipo = tipo {
            return all.filter { $0.tipo == tipo }.count
        }
        return all.count
    }

    func insertTransaccion(_ transaccion: Transaccion) async throws {
        modelContext.insert(transaccion)
        try modelContext.save()
    }

    func updateTransaccion(_ transaccion: Transaccion) async throws {
        try modelContext.save()
    }

    func deleteTransaccion(_ transaccion: Transaccion) async throws {
        modelContext.delete(transaccion)
        try modelContext.save()
    }

    func deleteTransaccion(by id: UUID) async throws {
        let descriptor = FetchDescriptor<Transaccion>(
            predicate: #Predicate { $0.id == id }
        )
        if let transaccion = try modelContext.fetch(descriptor).first {
            modelContext.delete(transaccion)
            try modelContext.save()
        }
    }

    func getTransaccion(by id: UUID) async throws -> Transaccion? {
        let descriptor = FetchDescriptor<Transaccion>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getAllCategorias() async throws -> [Categoria] {
        let descriptor = FetchDescriptor<Categoria>(
            sortBy: [SortDescriptor(\.nombre, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func insertCategoria(_ categoria: Categoria) async throws {
        modelContext.insert(categoria)
        try modelContext.save()
    }

    func updateCategoria(_ categoria: Categoria) async throws {
        try modelContext.save()
    }

    func deleteCategoria(_ categoria: Categoria) async throws {
        modelContext.delete(categoria)
        try modelContext.save()
    }

    func getUsuario() async throws -> Usuario? {
        let descriptor = FetchDescriptor<Usuario>(
            predicate: #Predicate { $0.id == 1 }
        )
        return try modelContext.fetch(descriptor).first
    }

    func upsertUsuario(_ usuario: Usuario) async throws {
        let descriptor = FetchDescriptor<Usuario>(
            predicate: #Predicate { $0.id == 1 }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.nombre = usuario.nombre
            existing.email = usuario.email
            existing.fechaNacimiento = usuario.fechaNacimiento
            existing.monedaPrincipal = usuario.monedaPrincipal
            existing.tema = usuario.tema
            existing.onboardingCompletado = usuario.onboardingCompletado
        } else {
            modelContext.insert(usuario)
        }
        try modelContext.save()
    }

    func getPresupuestos(mes: Int, anho: Int) async throws -> [PresupuestoCategoria] {
        let allPresupuestos = try modelContext.fetch(FetchDescriptor<PresupuestoCategoria>())
        return allPresupuestos.filter { $0.mes == mes && $0.anho == anho }
    }

    func getPresupuesto(categoriaId: UUID, mes: Int, anho: Int) async throws -> PresupuestoCategoria? {
        let allPresupuestos = try modelContext.fetch(FetchDescriptor<PresupuestoCategoria>())
        return allPresupuestos.first {
            $0.categoriaId == categoriaId && $0.mes == mes && $0.anho == anho
        }
    }

    func upsertPresupuesto(_ presupuesto: PresupuestoCategoria) async throws {
        let allPresupuestos = try modelContext.fetch(FetchDescriptor<PresupuestoCategoria>())

        if let existing = allPresupuestos.first(where: {
            $0.categoriaId == presupuesto.categoriaId &&
            $0.mes == presupuesto.mes &&
            $0.anho == presupuesto.anho &&
            $0.moneda == presupuesto.moneda
        }) {
            existing.monto = presupuesto.monto
            existing.categoriaId = presupuesto.categoriaId
        } else {
            modelContext.insert(presupuesto)
        }
        try modelContext.save()
    }

    func deletePresupuesto(_ presupuesto: PresupuestoCategoria) async throws {
        modelContext.delete(presupuesto)
        try modelContext.save()
    }

    func getAllMesesCerrados() async throws -> [MesCerrado] {
        let descriptor = FetchDescriptor<MesCerrado>(
            sortBy: [SortDescriptor(\.fechaCierre, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getMesCerrado(mes: Int, anho: Int) async throws -> MesCerrado? {
        let allMeses = try modelContext.fetch(FetchDescriptor<MesCerrado>())
        return allMeses.first { $0.mes == mes && $0.anho == anho }
    }
}
