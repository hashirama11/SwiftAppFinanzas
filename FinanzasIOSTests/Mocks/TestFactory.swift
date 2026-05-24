import Foundation
@testable import FinanzasIOS

enum TestFactory {
    static func makeUsuario(
        nombre: String = "Test User",
        tema: TemaApp = .claro,
        onboardingCompletado: Bool = true
    ) -> Usuario {
        Usuario(
            id: 1,
            nombre: nombre,
            email: nil,
            fechaNacimiento: nil,
            monedaPrincipal: .VES,
            tema: tema,
            onboardingCompletado: onboardingCompletado
        )
    }

    static func makeCategoria(
        id: UUID = UUID(),
        nombre: String,
        icono: IconosEstandar = .supermercado,
        tipo: TipoTransaccion = .gasto,
        esPersonalizada: Bool = false
    ) -> Categoria {
        Categoria(
            id: id,
            nombre: nombre,
            icono: icono,
            tipo: tipo,
            esPersonalizada: esPersonalizada
        )
    }

    static func makeTransaccion(
        id: UUID = UUID(),
        monto: Double = 100.0,
        moneda: Moneda = .VES,
        descripcion: String = "Test",
        fecha: Date = Date(),
        tipo: TipoTransaccion = .gasto,
        estado: EstadoTransaccion = .concretado,
        categoria: Categoria? = nil
    ) -> Transaccion {
        Transaccion(
            id: id,
            monto: monto,
            moneda: moneda,
            descripcion: descripcion,
            fecha: fecha,
            tipo: tipo,
            estado: estado,
            categoria: categoria
        )
    }
}
