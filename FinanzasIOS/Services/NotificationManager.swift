import Foundation
import UIKit
import UserNotifications
import Observation

@MainActor
@Observable
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    var isAuthorized: Bool = false
    var pendingCount: Int = 0

    private let center = UNUserNotificationCenter.current()

    override private init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            if granted {
                await refreshPendingCount()
            }
            return granted
        } catch {
            isAuthorized = false
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
        if isAuthorized {
            await refreshPendingCount()
        }
    }

    func scheduleNotification(for transaccion: Transaccion) async {
        guard let fechaConcrecion = transaccion.fechaConcrecion,
              fechaConcrecion > Date(),
              transaccion.isPending else { return }

        let content = UNMutableNotificationContent()
        content.title = "Recordatorio de Transacción"
        content.body = "\(transaccion.descripcion) — \(transaccion.monedaEnum.simbolo)\(String(format: "%.2f", transaccion.monto))"
        content.sound = .default
        content.badge = NSNumber(value: pendingCount + 1)

        if let categoria = transaccion.categoria {
            content.userInfo = [
                "transactionId": transaccion.id.uuidString,
                "categoryIcon": categoria.iconoEnum.sfSymbol
            ]
        }

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fechaConcrecion
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let identifier = "transaction-\(transaccion.id.uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            await refreshPendingCount()
        } catch {
            print("NotificationManager: error scheduling — \(error.localizedDescription)")
        }
    }

    func cancelNotification(for transaccion: Transaccion) {
        let identifier = "transaction-\(transaccion.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        Task { await refreshPendingCount() }
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        pendingCount = 0
    }

    func refreshPendingCount() async {
        let requests = await center.pendingNotificationRequests()
        pendingCount = requests.count
    }

    func openAppNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
