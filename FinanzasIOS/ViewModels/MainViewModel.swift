import Foundation
import SwiftData
import Observation

@Observable
final class MainViewModel {
    var isDarkTheme: Bool = false
    var onboardingCompleted: Bool? = nil

    private let repository: FinanzasRepository

    init(repository: FinanzasRepository) {
        self.repository = repository
    }

    func loadUser() async {
        guard let usuario = try? await repository.getUsuario() else {
            isDarkTheme = false
            onboardingCompleted = false
            return
        }
        isDarkTheme = usuario.isDarkTheme
        onboardingCompleted = usuario.onboardingCompletado
    }
}
