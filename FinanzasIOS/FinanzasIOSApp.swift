import SwiftUI
import SwiftData

@main
struct FinanzasIOSApp: App {
    private let modelContainer: ModelContainer

    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @State private var mainViewModel: MainViewModel?

    private static let currentSchemaVersion = 6

    init() {
        let schema = Schema([
            Usuario.self,
            Categoria.self,
            Transaccion.self,
            PresupuestoCategoria.self,
            MesCerrado.self,
        ])

        let storedVersion = UserDefaults.standard.integer(forKey: "schemaVersion")
        if storedVersion < Self.currentSchemaVersion {
            Self.deleteDefaultStore()
        }

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            UserDefaults.standard.set(Self.currentSchemaVersion, forKey: "schemaVersion")
        } catch {
            Self.deleteDefaultStore()

            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [configuration]
                )
                UserDefaults.standard.set(Self.currentSchemaVersion, forKey: "schemaVersion")
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    private static func deleteDefaultStore() {
        let storeURL = URL.applicationSupportDirectory
            .appending(path: "default.store")
        try? FileManager.default.removeItem(at: storeURL)
        try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
        try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(mainViewModel: mainViewModel)
                .environment(\.appTheme, isDarkMode ? .dark : .light)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .animation(.easeInOut(duration: 0.35), value: isDarkMode)
                .task {
                    await initializeApp()
                }
        }
        .modelContainer(modelContainer)
    }

    private func initializeApp() async {
        let context = modelContainer.mainContext
        await DefaultDataSeeder.seedIfNeeded(context: context)

        let repository = FinanzasRepositoryImpl(modelContext: context)
        let viewModel = MainViewModel(repository: repository)
        await viewModel.loadUser()

        isDarkMode = viewModel.isDarkTheme
        mainViewModel = viewModel

        let granted = await NotificationManager.shared.requestAuthorization()
        if granted {
            await NotificationManager.shared.refreshPendingCount()
        }

        await MonthTransitionService.checkAndTransition(context: context)
    }
}
