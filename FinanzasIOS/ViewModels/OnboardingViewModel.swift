import Foundation
import Observation

@Observable
final class OnboardingViewModel {
    private let repository: FinanzasRepository

    init(repository: FinanzasRepository) {
        self.repository = repository
    }

    func completeOnboarding(name: String, email: String = "", birthDate: Date? = nil) async {
        let existing = try? await repository.getUsuario()

        let displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let usuario = Usuario(
            id: 1,
            nombre: displayName.isEmpty ? "Usuario" : displayName,
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
            fechaNacimiento: birthDate,
            monedaPrincipal: existing?.monedaPrincipalEnum ?? .VES,
            tema: existing?.temaEnum ?? .claro,
            onboardingCompletado: true
        )

        try? await repository.upsertUsuario(usuario)
    }
}
