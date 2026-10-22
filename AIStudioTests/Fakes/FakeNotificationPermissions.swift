@testable import AIStudio

actor FakeNotificationPermissions: NotificationPermissionProviding {
    private(set) var requestCount = 0
    private var permission: NotificationPermission
    private let answer: NotificationPermission

    /// `answer` — то, что пользователь выберет в системном запросе.
    init(permission: NotificationPermission, answer: NotificationPermission = .allowed) {
        self.permission = permission
        self.answer = answer
    }

    func currentPermission() async -> NotificationPermission {
        permission
    }

    func requestPermission() async -> NotificationPermission {
        requestCount += 1
        if permission == .notDetermined {
            permission = answer
        }
        return permission
    }
}
