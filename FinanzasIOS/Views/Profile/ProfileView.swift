import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    let onCategoryManagementClick: () -> Void
    var onNotificationsClick: (() -> Void)?

    @State private var viewModel: ProfileViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                profileContent(vm: vm)
            } else {
                loadingView
            }
        }
        .background(theme.colors.background)
        .task {
            await setupViewModel()
            await NotificationManager.shared.checkAuthorizationStatus()
        }
    }

    @ViewBuilder
    private func profileContent(vm: ProfileViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                userHeader(vm: vm)
                preferencesSection
                dataSection
                aboutSection
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func userHeader(vm: ProfileViewModel) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.colors.primary, theme.colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)

                Text(userInitials(vm))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: theme.colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)

            VStack(spacing: 4) {
                Text(vm.user?.nombre ?? "Usuario")
                    .font(theme.typography.titleLarge)
                    .foregroundColor(theme.colors.textPrimary)

                if let email = vm.user?.email, !email.isEmpty {
                    Text(email)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding(.top, 12)
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Preferencias")

            VStack(spacing: 0) {
                darkModeToggle
                Divider().padding(.leading, 56)
                notificationsRow
            }
            .cardBackground()
        }
    }

    private var darkModeToggle: some View {
        HStack(spacing: 14) {
            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                .font(.system(size: 18))
                .foregroundColor(isDarkMode ? .indigo : .orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("Modo Oscuro")
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textPrimary)
                Text(isDarkMode ? "Activado" : "Desactivado")
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $isDarkMode)
                .tint(theme.colors.primary)
                .onChange(of: isDarkMode) { _, newValue in
                    Task {
                        await viewModel?.updateTheme(newValue ? .oscuro : .claro)
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var notificationsRow: some View {
        Button {
            onNotificationsClick?()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundColor(theme.colors.primary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Notificaciones")
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(theme.colors.textPrimary)
                    Text("Gestionar recordatorios")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Datos")

            VStack(spacing: 0) {
                NavigationLinkButton(
                    icon: "tag.fill",
                    iconColor: theme.colors.primary,
                    title: "Gestionar Categorías",
                    subtitle: "Crea y administra categorías personalizadas",
                    action: onCategoryManagementClick
                )
            }
            .cardBackground()
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Acerca de")

            VStack(spacing: 0) {
                infoRow(icon: "app.badge.fill", iconColor: .blue, title: "Versión", value: "1.0.0")
                Divider().padding(.leading, 56)
                infoRow(icon: "swift", iconColor: .orange, title: "Plataforma", value: "iOS 17+")
                Divider().padding(.leading, 56)
                infoRow(icon: "cpu.fill", iconColor: .purple, title: "Base de datos", value: "SwiftData")
            }
            .cardBackground()
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(theme.typography.labelMedium)
            .foregroundColor(theme.colors.textSecondary)
            .textCase(.uppercase)
            .padding(.leading, 4)
    }

    private func infoRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 28)

            Text(title)
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            Text(value)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func userInitials(_ vm: ProfileViewModel) -> String {
        let name = vm.user?.nombre ?? "U"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }

    private func setupViewModel() async {
        let repo = FinanzasRepositoryImpl(modelContext: modelContext)
        let vm = ProfileViewModel(repository: repo)
        await vm.loadUser()
        viewModel = vm

        isDarkMode = vm.user?.isDarkTheme ?? false
    }

    private var loadingView: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            ProgressView().tint(theme.colors.primary).scaleEffect(1.2)
        }
    }
}

private struct NavigationLinkButton: View {
    @Environment(\.appTheme) private var theme

    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(theme.colors.textPrimary)
                    Text(subtitle)
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}
