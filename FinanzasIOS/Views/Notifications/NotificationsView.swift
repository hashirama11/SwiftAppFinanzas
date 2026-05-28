import SwiftUI

struct NotificationsView: View {
    @Environment(\.appTheme) private var theme

    @State private var viewModel = NotificationsViewModel()
    var onBack: (() -> Void)?

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else {
                contentView
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Alertas")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(onBack != nil)
        .toolbar {
            if let onBack = onBack {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").font(.body.weight(.semibold))
                            Text("Atrás")
                        }
                        .foregroundColor(theme.colors.primary)
                    }
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .transactionDidChange) {
                await viewModel.loadData()
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                    .padding(.horizontal, 20)

                if !viewModel.isAuthorized {
                    permissionsCard
                        .padding(.horizontal, 20)
                } else if viewModel.pendingNotifications.isEmpty {
                    emptyState
                } else {
                    notificationsList
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notificaciones")
                .font(theme.typography.headlineMedium)
                .foregroundColor(theme.colors.textPrimary)

            if viewModel.isAuthorized {
                Text("\(viewModel.pendingNotifications.count) recordatorio\(viewModel.pendingNotifications.count == 1 ? "" : "s") pendiente\(viewModel.pendingNotifications.count == 1 ? "" : "s")")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var permissionsCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.textSecondary.opacity(0.5))

            VStack(spacing: 8) {
                Text("Notificaciones Desactivadas")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.colors.textPrimary)

                Text("Activa las notificaciones para recibir recordatorios de tus transacciones pendientes")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.requestPermissions() }
            } label: {
                Text("Activar Notificaciones")
                    .font(theme.typography.labelMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: theme.shapes.pill))
            }

            Button {
                viewModel.openSettings()
            } label: {
                Text("Abrir Configuración")
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.colors.primary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.shapes.medium))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
    }

    private var notificationsList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.pendingNotifications) { notification in
                NotificationCard(notification: notification) {
                    Task { await viewModel.cancelNotification(notification) }
                }

                if notification.id != viewModel.pendingNotifications.last?.id {
                    Divider()
                        .padding(.leading, 20)
                }
            }
        }
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.shapes.medium))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.primary.opacity(0.4))

            VStack(spacing: 8) {
                Text("Sin Recordatorios")
                    .font(theme.typography.titleMedium)
                    .foregroundColor(theme.colors.textPrimary)

                Text("No tienes transacciones pendientes con recordatorio programado")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }

    private var loadingView: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            ProgressView()
                .tint(theme.colors.primary)
                .scaleEffect(1.2)
        }
    }
}

private struct NotificationCard: View {
    @Environment(\.appTheme) private var theme

    let notification: PendingNotification
    let onCancel: () -> Void

    @State private var showCancelConfirmation: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                notificationIcon
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(notification.tipo == .ingreso ? "Ingreso" : "Gasto")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(notification.tipo == .ingreso ? theme.colors.accentGreen : theme.colors.accentRed)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                (notification.tipo == .ingreso ? theme.colors.accentGreen : theme.colors.accentRed)
                                    .opacity(0.12)
                            )
                            .clipShape(Capsule())

                        Text("Recordatorio")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(theme.colors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(theme.colors.primary.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Text(notification.descripcion)
                        .font(theme.typography.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)

                    if let categoria = notification.categoria, !categoria.isEmpty {
                        Text(categoria)
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(amountString)
                        .font(theme.typography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(notification.tipo == .ingreso ? theme.colors.accentGreen : theme.colors.accentRed)

                    Text(Formatters.formatDateShort(notification.fechaProgramada))
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }

            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.textSecondary)

                Text("Programado: \(Formatters.formatDate(notification.fechaProgramada))")
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.colors.textSecondary)

                Spacer()

                Button {
                    showCancelConfirmation = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Cancelar")
                            .font(theme.typography.labelSmall)
                    }
                    .foregroundColor(theme.colors.accentRed)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.colors.accentRed.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .alert("Cancelar Recordatorio", isPresented: $showCancelConfirmation) {
            Button("Mantener", role: .cancel) { }
            Button("Cancelar", role: .destructive) { onCancel() }
        } message: {
            Text("¿Deseas cancelar este recordatorio para '\(notification.descripcion)'?")
        }
    }

    private var notificationIcon: some View {
        let iconName = notification.tipo == .ingreso ? "arrow.down.left" : "arrow.up.right"

        return Image(systemName: iconName)
            .font(.system(size: 16))
            .foregroundColor(notification.tipo == .ingreso ? theme.colors.accentGreen : theme.colors.accentRed)
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(
                        (notification.tipo == .ingreso ? theme.colors.accentGreen : theme.colors.accentRed)
                            .opacity(0.1)
                    )
            )
    }

    private var amountString: String {
        let prefix = notification.tipo == .ingreso ? "+" : "-"
        let formatted = Formatters.currency.string(from: NSNumber(value: notification.monto))
            ?? String(format: "%.2f", notification.monto)
        return "\(prefix)\(notification.moneda.simbolo) \(formatted)"
    }
}

#Preview {
    NotificationsView()
}
