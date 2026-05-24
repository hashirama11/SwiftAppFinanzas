# Finanzas

Tu asistente personal para tomar el control de tus ingresos y gastos de una manera sencilla e intuitiva.

<div align="center">
  <img src="Assets/AppIcon.png" alt="Finanzas" width="120" />
</div>

---

## Características

- **Dashboard** – Resumen de ingresos y gastos con gráficos de pastel por categoría y lista de transacciones recientes.
- **Balance** – Balance neto en VES (Bs.) y USD ($), tasa de ahorro con barra de progreso y gráfico de barras mensual de los últimos 6 meses.
- **Agregar / Editar transacciones** – Formulario completo con tipo, monto, moneda, descripción, fecha, categoría y estado (concretado o pendiente).
- **Lista de transacciones** – Búsqueda y filtrado de todas las transacciones registradas.
- **Gestión de categorías** – Crea categorías personalizadas además de las 48 categorías estándar incluidas.
- **Doble moneda** – Soporte para Bolívares (VES) y Dólares (USD).
- **Notificaciones locales** – Recordatorios para transacciones pendientes con fecha de vencimiento.
- **Modo oscuro / claro** – Tema adaptable que se puede cambiar desde el perfil.
- **Perfil de usuario** – Configura tu nombre y preferencias.
- **Onboarding** – Pantalla de bienvenida para la primera ejecución.

---

## Stack tecnológico

| Tecnología | Uso |
|---|---|
| **SwiftUI** | Framework de interfaz de usuario |
| **SwiftData** | Persistencia local |
| **Swift Charts** | Gráficos de pastel y barras |
| **MVVM + Protocol-Oriented** | Arquitectura con inyección de dependencias |
| **UserNotifications** | Notificaciones locales |
| **Sin dependencias externas** | Solo frameworks nativos de Apple |

---

## Arquitectura

```
Views (SwiftUI)
    ↕
ViewModels (@Observable)
    ↕
Repository (Protocolo FinanzasRepository)
    ↕
SwiftData (ModelContainer)
```

- **MVVM** con ViewModels `@Observable` que consumen un repositorio mediante inyección de dependencias.
- El repositorio (`FinanzasRepository`) es un protocolo que permite testing con mocks en memoria.
- Las vistas se comunican entre sí mediante `NotificationCenter` para refrescar datos.

---

## Requisitos

- Xcode 16.5+
- iOS 18.5+
- Swift 5.0

*También compatible con iPad, Mac (Designed for iPad) y Apple Vision Pro.*

---

## Instalación

1. Clona el repositorio:

```bash
git clone https://github.com/chesterDarial/FinanzasIOS.git
```

2. Abre `FinanzasIOS.xcodeproj` con Xcode.

3. Selecciona un simulador o dispositivo y presiona **Run** (⌘R).

*No se requieren dependencias externas ni configuración adicional.*

---

## Estructura del proyecto

```
FinanzasIOS/
├── Models/
│   ├── Enums/              # Tipos, estados, monedas, temas, iconos
│   ├── SwiftData/          # Modelos: Usuario, Categoria, Transaccion
│   └── UI/                 # Wrappers para vistas (PieChartData, MonthlyFlow)
├── ViewModels/             # Lógica de negocio y estados inmutables
├── Views/
│   ├── Dashboard/          # Pantalla principal con gráficos y resumen
│   ├── Balance/            # Balance neto y tasa de ahorro
│   ├── AddTransaction/     # Formulario de creación/edición
│   ├── AllTransactions/    # Lista completa con búsqueda
│   ├── TransactionDetail/  # Detalle y eliminación
│   ├── Profile/            # Perfil de usuario y configuración
│   ├── Onboarding/         # Pantalla de bienvenida
│   └── Components/         # Componentes reutilizables
├── Services/
│   ├── FinanzasRepository  # Capa de acceso a datos
│   ├── DefaultDataSeeder   # Siembra inicial de datos
│   └── NotificationManager # Gestión de notificaciones
├── Navigation/             # Rutas y TabView
├── Theme/                  # Sistema de diseño (colores, tipografía)
├── Helpers/                # Formateadores y utilidades
└── FinanzasIOSTests/       # Tests unitarios y de integración
```

---

## Categorías estándar incluidas

Alquiler, Supermercado, Transporte, Restaurantes, Salud, Educación, Entretenimiento, Ropa, Servicios (agua, luz, gas, internet, teléfono), Seguros, Impuestos, Viajes, Mascotas, Regalos, Banca, Donaciones, Hogar, Tecnología, Ejercicio, Salario, Freelance, Inversiones, Negocio, Aguinaldos, y más.

---

## Licencia

Este proyecto es de código abierto. Consulta el archivo `LICENSE` para más información.
