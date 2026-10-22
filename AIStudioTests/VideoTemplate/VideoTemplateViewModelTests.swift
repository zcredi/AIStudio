import XCTest
@testable import AIStudio

@MainActor
final class VideoTemplateViewModelTests: XCTestCase {
    private let photo = LoadedPhoto(jpegData: Data([1, 2, 3]), thumbnailData: Data([4]))

    // MARK: - Templates

    func test_init_prefersRecommendedQuality() {
        let viewModel = makeViewModel(template: .fixture(qualities: [.p360, .p720, .p1080]))

        XCTAssertEqual(viewModel.state.quality, .p1080)
    }

    func test_selectTemplate_withoutCurrentQuality_fallsBackToBestAvailable() {
        // Дано
        let first = VideoTemplate.fixture(id: 1, qualities: [.p720, .p1080])
        let second = VideoTemplate.fixture(id: 2, qualities: [.p360, .p540])
        let viewModel = makeViewModel(template: first, templates: [first, second])

        // Когда
        viewModel.selectTemplate(at: 1)

        // Тогда
        XCTAssertEqual(viewModel.state.template, second)
        XCTAssertEqual(viewModel.state.quality, .p540)
    }

    func test_selectQuality_notOfferedByTemplate_isIgnored() {
        let viewModel = makeViewModel(template: .fixture(qualities: [.p720, .p1080]))

        viewModel.selectQuality(.p360)

        XCTAssertEqual(viewModel.state.quality, .p1080)
    }

    // MARK: - Photo access

    func test_addPhoto_withAccess_opensPicker() {
        let viewModel = makeViewModel(access: FakePhotoLibraryAccess(current: .granted))
        let events = PublisherRecorder(viewModel.events)

        viewModel.addPhotoTapped()

        XCTAssertEqual(events.values, [.showPhotoPicker])
    }

    func test_addPhoto_whenUserAllowsAccess_opensPicker() async {
        let viewModel = makeViewModel(access: FakePhotoLibraryAccess(current: .notDetermined, answer: .granted))
        let events = PublisherRecorder(viewModel.events)

        await viewModel.addPhotoTapped()?.value

        XCTAssertEqual(events.values, [.showPhotoPicker])
    }

    func test_addPhoto_whenUserDeclinesPrompt_staysOnScreen() async {
        let viewModel = makeViewModel(access: FakePhotoLibraryAccess(current: .notDetermined, answer: .denied))
        let events = PublisherRecorder(viewModel.events)

        await viewModel.addPhotoTapped()?.value

        XCTAssertTrue(events.values.isEmpty)
    }

    func test_addPhoto_whenDeniedBefore_pointsToSettings() {
        let viewModel = makeViewModel(access: FakePhotoLibraryAccess(current: .denied))
        let events = PublisherRecorder(viewModel.events)

        viewModel.addPhotoTapped()

        XCTAssertEqual(events.values, [.showPhotoAccessDenied])
    }

    // MARK: - Photo

    func test_loadPhoto_showsThumbnailAndEnablesCreate() async {
        let viewModel = makeViewModel()

        await viewModel.loadPhoto { [photo] in photo }.value

        XCTAssertEqual(viewModel.state.photo, .loaded(thumbnail: photo.thumbnailData))
        XCTAssertTrue(viewModel.state.canCreate)
    }

    func test_loadPhoto_whenFails_showsUploadFailedAndEmptySlot() async {
        let viewModel = makeViewModel()
        let events = PublisherRecorder(viewModel.events)

        await viewModel.loadPhoto { throw PhotoLoaderError.unreadableImage }.value

        XCTAssertEqual(viewModel.state.photo, .empty)
        XCTAssertFalse(viewModel.state.canCreate)
        XCTAssertEqual(events.values, [.showToast(.uploadFailed)])
    }

    func test_removePhoto_disablesCreate() async {
        let viewModel = makeViewModel()
        await viewModel.loadPhoto { [photo] in photo }.value

        viewModel.removePhoto()

        XCTAssertEqual(viewModel.state.photo, .empty)
        XCTAssertFalse(viewModel.state.canCreate)
    }

    // MARK: - Create

    func test_create_startsGenerationWithChosenParameters() async throws {
        // Дано
        let generator = FakeVideoGenerator()
        let viewModel = makeViewModel(generator: generator)
        let events = PublisherRecorder(viewModel.events)
        await viewModel.loadPhoto { [photo] in photo }.value
        viewModel.selectFormat(.square)
        viewModel.selectQuality(.p720)

        // Когда
        await viewModel.createTapped()?.value

        // Тогда
        let request = try XCTUnwrap(generator.requests.first)
        XCTAssertEqual(request.format, .square)
        XCTAssertEqual(request.quality, .p720)
        XCTAssertEqual(request.photo, photo.jpegData)
        guard case .openGeneration = events.values.last else { return XCTFail("Expected navigation") }
        XCTAssertFalse(viewModel.state.isStarting)
    }

    func test_create_forFreeUser_showsPaywallOnly() async {
        let generator = FakeVideoGenerator()
        let gate = FakePremiumGate()
        gate.isPremium = false
        let viewModel = makeViewModel(generator: generator, gate: gate)
        await viewModel.loadPhoto { [photo] in photo }.value

        let task = viewModel.createTapped()

        XCTAssertNil(task)
        XCTAssertEqual(gate.paywallRequestCount, 1)
        XCTAssertTrue(generator.requests.isEmpty)
    }

    func test_create_withoutPhoto_doesNothing() {
        let generator = FakeVideoGenerator()
        let viewModel = makeViewModel(generator: generator)

        XCTAssertNil(viewModel.createTapped())
        XCTAssertTrue(generator.requests.isEmpty)
    }

    // MARK: - Private

    private func makeViewModel(
        template: VideoTemplate = .fixture(),
        templates: [VideoTemplate]? = nil,
        generator: FakeVideoGenerator = FakeVideoGenerator(),
        gate: FakePremiumGate = FakePremiumGate(),
        access: FakePhotoLibraryAccess = FakePhotoLibraryAccess(current: .granted)
    ) -> VideoTemplateViewModel {
        VideoTemplateViewModel(
            template: template,
            templates: templates ?? [template],
            generator: generator,
            premiumGate: gate,
            photoAccess: access
        )
    }
}
