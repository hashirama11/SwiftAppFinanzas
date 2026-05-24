import Foundation
import Observation

@Observable
final class ProfileViewModel {
    var user: Usuario? = nil

    private let repository: FinanzasRepository

    init(repository: FinanzasRepository) {
        self.repository = repository
    }

    func loadUser() async {
        user = try? await repository.getUsuario()
    }

    func updateTheme(_ tema: TemaApp) async {
        guard let currentUser = user else { return }
        currentUser.temaEnum = tema
        try? await repository.upsertUsuario(currentUser)
        user = currentUser
    }
}
