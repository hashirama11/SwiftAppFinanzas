import SwiftUI

struct ContentView: View {
    @Environment(\.appTheme) private var theme

    let mainViewModel: MainViewModel?

    @State private var hasSeenOnboarding: Bool = false

    private var shouldShowOnboarding: Bool {
        guard let vm = mainViewModel else { return false }
        return vm.onboardingCompleted == false && !hasSeenOnboarding
    }

    var body: some View {
        ZStack {
            if mainViewModel != nil {
                Group {
                    if shouldShowOnboarding {
                        OnboardingView {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                hasSeenOnboarding = true
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        AppTabView()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: shouldShowOnboarding)
            } else {
                launchScreen
            }
        }
    }

    private var launchScreen: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.colors.primary, theme.colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(1.0)
                    .opacity(1.0)

                Text("Finanzas")
                    .font(theme.typography.displayLarge)
                    .foregroundColor(theme.colors.textPrimary)

                ProgressView()
                    .tint(theme.colors.primary)
                    .scaleEffect(1.2)
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    ContentView(mainViewModel: nil)
}
