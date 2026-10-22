import XCTest
@testable import AIStudio

@MainActor
final class VideoResultViewModelTests: XCTestCase {
    private let generation = VideoGeneration.fixture(format: .square, state: .ready, isNew: true)
    private let photo = LoadedPhoto(jpegData: Data([1, 2, 3]), thumbnailData: Data([4]))

    func test_init_startsPaused() {
        let viewModel = makeViewModel()

        XCTAssertFalse(viewModel.state.isPlaying)
        XCTAssertEqual(viewModel.state.format, .square)
    }

    func test_viewDidAppear_marksResultSeen() {
        let generator = FakeVideoGenerator()
        let viewModel = makeViewModel(generator: generator)

        viewModel.viewDidAppear()

        XCTAssertEqual(generator.seenIDs, [generation.id])
    }

    func test_togglePlayback_playsAndPauses() {
        let viewModel = makeViewModel()

        viewModel.togglePlayback()
        XCTAssertTrue(viewModel.state.isPlaying)

        viewModel.togglePlayback()
        XCTAssertFalse(viewModel.state.isPlaying)
    }

    func test_download_whenSaved_reportsSuccess() async {
        // Дано
        let saver = FakeVideoSaver()
        let viewModel = makeViewModel(saver: saver)
        let events = PublisherRecorder(viewModel.events)

        // Когда
        await viewModel.downloadTapped()?.value

        // Тогда
        XCTAssertEqual(events.values, [.showSaveResult(.saved)])
        let savedURLs = await saver.savedURLs
        XCTAssertEqual(savedURLs, [viewModel.state.videoURL])
        XCTAssertFalse(viewModel.state.isSaving)
    }

    func test_download_whenFails_reportsFailure() async {
        let viewModel = makeViewModel(saver: FakeVideoSaver(error: .failed))
        let events = PublisherRecorder(viewModel.events)

        await viewModel.downloadTapped()?.value

        XCTAssertEqual(events.values, [.showSaveResult(.failed)])
    }

    func test_download_withoutAccess_asksForSettings() async {
        let viewModel = makeViewModel(saver: FakeVideoSaver(error: .accessDenied))
        let events = PublisherRecorder(viewModel.events)

        await viewModel.downloadTapped()?.value

        XCTAssertEqual(events.values, [.showSaveResult(.accessDenied)])
    }

    func test_replace_generatesWithSameParametersAndNewPhoto() async throws {
        // Дано
        let generator = FakeVideoGenerator()
        let viewModel = makeViewModel(generator: generator)
        let events = PublisherRecorder(viewModel.events)

        // Когда
        viewModel.replaceTapped()
        await viewModel.replacePhoto { [photo] in photo }.value

        // Тогда
        let request = try XCTUnwrap(generator.requests.first)
        XCTAssertEqual(request.templateID, generation.templateID)
        XCTAssertEqual(request.format, generation.format)
        XCTAssertEqual(request.quality, generation.quality)
        XCTAssertEqual(request.photo, photo.jpegData)
        XCTAssertEqual(events.values.first, .showPhotoPicker)
        guard case .openGeneration = events.values.last else { return XCTFail("Expected navigation") }
    }

    func test_replace_forFreeUser_showsPaywall() {
        let gate = FakePremiumGate()
        gate.isPremium = false
        let viewModel = makeViewModel(gate: gate)
        let events = PublisherRecorder(viewModel.events)

        viewModel.replaceTapped()

        XCTAssertEqual(gate.paywallRequestCount, 1)
        XCTAssertTrue(events.values.isEmpty)
    }

    func test_replace_whenPhotoFails_showsUploadFailed() async {
        let generator = FakeVideoGenerator()
        let viewModel = makeViewModel(generator: generator)
        let events = PublisherRecorder(viewModel.events)

        await viewModel.replacePhoto { throw PhotoLoaderError.unreadableImage }.value

        XCTAssertEqual(events.values, [.showToast(.uploadFailed)])
        XCTAssertTrue(generator.requests.isEmpty)
        XCTAssertFalse(viewModel.state.isReplacing)
    }

    // MARK: - Private

    private func makeViewModel(
        generator: FakeVideoGenerator = FakeVideoGenerator(),
        saver: FakeVideoSaver = FakeVideoSaver(),
        gate: FakePremiumGate = FakePremiumGate()
    ) -> VideoResultViewModel {
        VideoResultViewModel(
            generation: generation,
            generator: generator,
            saver: saver,
            premiumGate: gate,
            photoAccess: FakePhotoLibraryAccess(current: .granted)
        )
    }
}
