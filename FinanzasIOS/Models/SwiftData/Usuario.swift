import Foundation
import SwiftData

@Model
final class Usuario {
    @Attribute(.unique) var id: Int = 1
    var nombre: String
    var email: String?
    var fechaNacimiento: Date?
    var monedaPrincipal: String
    var tema: String
    var onboardingCompletado: Bool

    var monedaPrincipalEnum: Moneda {
        get { Moneda(rawValue: monedaPrincipal) ?? .VES }
        set { monedaPrincipal = newValue.rawValue }
    }

    var temaEnum: TemaApp {
        get { TemaApp(rawValue: tema) ?? .claro }
        set { tema = newValue.rawValue }
    }

    var isDarkTheme: Bool {
        temaEnum == .oscuro
    }

    init(
        id: Int = 1,
        nombre: String = "Usuario",
        email: String? = nil,
        fechaNacimiento: Date? = nil,
        monedaPrincipal: Moneda = .VES,
        tema: TemaApp = .claro,
        onboardingCompletado: Bool = false
    ) {
        self.id = id
        self.nombre = nombre
        self.email = email
        self.fechaNacimiento = fechaNacimiento
        self.monedaPrincipal = monedaPrincipal.rawValue
        self.tema = tema.rawValue
        self.onboardingCompletado = onboardingCompletado
    }
}
