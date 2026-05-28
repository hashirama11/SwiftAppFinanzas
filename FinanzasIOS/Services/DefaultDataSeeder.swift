import Foundation
import SwiftData

@MainActor
struct DefaultDataSeeder {
    static func seedIfNeeded(context: ModelContext) async {
        let userDescriptor = FetchDescriptor<Usuario>()
        let userCount = (try? context.fetchCount(userDescriptor)) ?? 0

        guard userCount == 0 else { return }

        let defaultUser = Usuario(
            id: 1,
            nombre: "Usuario",
            email: nil,
            fechaNacimiento: nil,
            monedaPrincipal: .VES,
            tema: .claro,
            onboardingCompletado: false
        )
        context.insert(defaultUser)

        let categoriasIngreso: [(nombre: String, icono: IconosEstandar)] = [
            ("Salario", .otros),
            ("Freelance", .otros),
            ("Inversiones", .interesesBancarios),
            ("Alquiler", .alquiler),
            ("Ventas", .otros),
            ("Bonos y Comisiones", .otros),
            ("Reembolsos", .otros),
            ("Regalos", .otros),
            ("Otros Ingresos", .otros),
        ]

        for (nombre, icono) in categoriasIngreso {
            let categoria = Categoria(
                nombre: nombre,
                icono: icono,
                tipo: .ingreso,
                esPersonalizada: false
            )
            context.insert(categoria)
        }

        for icono in IconosEstandar.allCases {
            let categoria = Categoria(
                nombre: icono.nombreLegible,
                icono: icono,
                tipo: .gasto,
                esPersonalizada: false
            )
            context.insert(categoria)
        }

        try? context.save()
    }
}
