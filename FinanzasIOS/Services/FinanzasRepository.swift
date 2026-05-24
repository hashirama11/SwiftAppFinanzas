import Foundation
import SwiftData

@MainActor
protocol FinanzasRepository: Sendable {
    func getAllTransacciones() async throws -> [Transaccion]
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
}
