import SwiftUI
import SwiftData

@main
struct FinanzasIOSApp: App {
    private let modelContainer: ModelContainer

    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @State private var mainViewModel: MainViewModel?

    init() {
        let schema = Schema([
            Usuario.self,
            Categoria.self,
            Transaccion.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
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
    }
}
