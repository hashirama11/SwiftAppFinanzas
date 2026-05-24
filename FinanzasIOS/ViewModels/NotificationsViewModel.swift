import Foundation
import Observation
import UserNotifications

@Observable
final class NotificationsViewModel {
    var isAuthorized: Bool = false
    var pendingNotifications: [PendingNotification] = []
    var isLoading: Bool = true

    func loadData() async {
        isLoading = true
        await NotificationManager.shared.checkAuthorizationStatus()
        await NotificationManager.shared.refreshPendingCount()
        isAuthorized = NotificationManager.shared.isAuthorized
        pendingNotifications = NotificationManager.shared.pendingNotifications
        isLoading = false
    }

    func requestPermissions() async {
        let granted = await NotificationManager.shared.requestAuthorization()
        isAuthorized = granted
        if granted {
            await NotificationManager.shared.refreshPendingCount()
            pendingNotifications = NotificationManager.shared.pendingNotifications
        }
    }

    func cancelNotification(_ notification: PendingNotification) async {
        center.removePendingNotificationRequests(withIdentifiers: [notification.id])
        await NotificationManager.shared.refreshPendingCount()
        pendingNotifications = NotificationManager.shared.pendingNotifications
    }

    func openSettings() {
        NotificationManager.shared.openAppNotificationSettings()
    }

    private var center: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }
}
