import XCTest
@testable import AIStudio

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func test_refresh_showsCacheSizeAndPermission() async {
        let viewModel = makeViewModel(cache: FakeCacheStorage(size: 5_000_000), permission: .allowed)

        await viewModel.refresh().value

        XCTAssertEqual(viewModel.state.cacheSize, Int64(5_000_000).formatted(.byteCount(style: .file)))
        XCTAssertTrue(viewModel.state.areNotificationsOn)
    }

    func test_setNotificationsEnabled_beforeAsking_requestsPermission() async {
        // Дано
        let permissions = FakeNotificationPermissions(permission: .notDetermined)
        let viewModel = makeViewModel(permissions: permissions)

        // Когда
        await viewModel.setNotificationsEnabled(true)?.value

        // Тогда
        XCTAssertTrue(viewModel.state.areNotificationsOn)
        let requestCount = await permissions.requestCount
        XCTAssertEqual(requestCount, 1)
    }

    func test_setNotificationsEnabled_whenDenied_opensSystemSettings() async {
        let viewModel = makeViewModel(permission: .denied)
        let events = PublisherRecorder(viewModel.events)

        await viewModel.setNotificationsEnabled(true)?.value

        XCTAssertEqual(events.values, [.openSystemSettings])
        XCTAssertFalse(viewModel.state.areNotificationsOn)
    }

    func test_setNotificationsDisabled_opensSystemSettings() {
        let viewModel = makeViewModel(permission: .allowed)
        let events = PublisherRecorder(viewModel.events)

        viewModel.setNotificationsEnabled(false)

        XCTAssertEqual(events.values, [.openSystemSettings])
    }

    func test_clearCacheTapped_clearsAndShowsNewSize() async {
        // Дано
        let cache = FakeCacheStorage(size: 5_000_000)
        let viewModel = makeViewModel(cache: cache)
        let events = PublisherRecorder(viewModel.events)

        // Когда
        await viewModel.clearCacheTapped().value

        // Тогда
        XCTAssertEqual(viewModel.state.cacheSize, Int64(0).formatted(.byteCount(style: .file)))
        XCTAssertEqual(events.values, [.showToast(.cacheCleared)])
    }

    func test_restoreTapped_withNothingToRestore_showsError() async throws {
        // Дано
        let subscription = FakeSubscriptionService()
        subscription.restoreError = SubscriptionError.nothingToRestore
        let viewModel = makeViewModel(subscription: subscription)
        let events = PublisherRecorder(viewModel.events)

        // Когда
        await viewModel.restoreTapped()?.value

        // Тогда
        let expected = try XCTUnwrap(UserFacingError(SubscriptionError.nothingToRestore))
        XCTAssertEqual(events.values, [.showError(expected)])
        XCTAssertFalse(viewModel.state.isRestoring)
    }

    func test_restoreTapped_whenRestored_confirms() async {
        let viewModel = makeViewModel()
        let events = PublisherRecorder(viewModel.events)

        await viewModel.restoreTapped()?.value

        XCTAssertEqual(events.values, [.showToast(.purchasesRestored)])
    }

    // MARK: - Private

    private func makeViewModel(
        subscription: FakeSubscriptionService = FakeSubscriptionService(),
        cache: FakeCacheStorage = FakeCacheStorage(size: 0),
        permission: NotificationPermission = .notDetermined,
        permissions: FakeNotificationPermissions? = nil
    ) -> SettingsViewModel {
        SettingsViewModel(
            subscriptionService: subscription,
            cache: cache,
            notifications: permissions ?? FakeNotificationPermissions(permission: permission),
            appVersion: "1.0.0"
        )
    }
}
