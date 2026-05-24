import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    let onFinish: () -> Void

    @State private var name: String = ""

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.colors.primary, theme.colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 12) {
                    Text("Bienvenido a Finanzas")
                        .font(theme.typography.headlineMedium)
                        .foregroundColor(theme.colors.textPrimary)

                    Text("Tu asistente personal para tomar el control de tus ingresos y gastos de una manera sencilla e intuitiva.")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 16) {
                    TextField("Tu nombre", text: $name)
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(theme.colors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: theme.shapes.small))
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.shapes.small)
                                .stroke(theme.colors.divider, lineWidth: 0.5)
                        )

                    Button {
                        Task {
                            let repo = FinanzasRepositoryImpl(modelContext: modelContext)
                            let vm = OnboardingViewModel(repository: repo)
                            await vm.completeOnboarding(name: name)
                            onFinish()
                        }
                    } label: {
                        Text("Comenzar")
                            .font(theme.typography.titleMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: theme.shapes.large)
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.colors.primary, theme.colors.secondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                }
                .padding(.horizontal, 48)
                .padding(.top, 16)
            }
        }
    }
}
