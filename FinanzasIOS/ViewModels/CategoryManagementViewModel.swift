import Foundation
import Observation

@Observable
final class CategoryManagementViewModel {
    var categories: [Categoria] = []

    private let repository: FinanzasRepository

    init(repository: FinanzasRepository) {
        self.repository = repository
    }

    func loadCategories() async {
        guard let allCategories = try? await repository.getAllCategorias() else { return }
        categories = allCategories.filter { $0.esPersonalizada }
    }

    func addCategory(name: String, type: TipoTransaccion, icon: IconosEstandar) async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let categoria = Categoria(
            nombre: name.trimmingCharacters(in: .whitespacesAndNewlines),
            icono: icon,
            tipo: type,
            esPersonalizada: true
        )

        try? await repository.insertCategoria(categoria)
        await loadCategories()
    }

    func deleteCategory(_ categoria: Categoria) async {
        try? await repository.deleteCategoria(categoria)
        await loadCategories()
    }

    func deleteCategory(by id: UUID) async {
        guard let categoria = categories.first(where: { $0.id == id }) else { return }
        await deleteCategory(categoria)
    }
}
