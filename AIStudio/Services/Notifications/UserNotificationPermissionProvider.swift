import OSLog
import UserNotifications

struct UserNotificationPermissionProvider: NotificationPermissionProviding {
    // MARK: - Properties

    private let logger = Logger(category: "UserNotificationPermissionProvider")

    // MARK: - NotificationPermissionProviding

    func currentPermission() async -> NotificationPermission {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return NotificationPermission(settings.authorizationStatus)
    }

    func requestPermission() async -> NotificationPermission {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            logger.error("Notification permission request failed: \(error)")
        }
        return await currentPermission()
    }
}

// MARK: - Mapping

private extension NotificationPermission {
    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .authorized, .provisional, .ephemeral:
            self = .allowed
        case .denied:
            self = .denied
        @unknown default:
            self = .denied
        }
    }
}
