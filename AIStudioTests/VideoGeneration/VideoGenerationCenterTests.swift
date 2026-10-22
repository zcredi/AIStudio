import Combine
import XCTest
@testable import AIStudio

@MainActor
final class VideoGenerationCenterTests: XCTestCase {
    private let resultURL = URL(filePath: "/remote/result.mp4")

    // MARK: - Generate

    func test_generate_whenServerSucceeds_downloadsResultAndMarksItNew() async throws {
        // Дано
        let repository = FakeVideoGenerationRepository(statuses: [.generating, .succeeded(videoURL: resultURL)])
        let library = FakeVideoLibrary()
        let center = makeCenter(repository: repository, library: library)

        // Когда
        let id = try await center.generate(makeRequest())
        await waitUntil(center) { $0.first?.state == .ready }

        // Тогда
        let generation = try XCTUnwrap(center.generations.first)
        XCTAssertEqual(generation.id, id)
        XCTAssertTrue(generation.isNew)
        XCTAssertEqual(generation.remoteID, 42)
        let downloads = await library.downloads
        XCTAssertEqual(downloads[id], resultURL)
    }

    func test_generate_addsInProgressGenerationRightAway() async throws {
        let center = makeCenter(repository: FakeVideoGenerationRepository(statuses: [.generating]))

        _ = try await center.generate(makeRequest())

        XCTAssertEqual(center.generations.map(\.state), [.inProgress])
        XCTAssertEqual(center.generations.first?.templateName, "Snowfall")
    }

    func test_generate_uploadsPhotoCroppedToFormat() async throws {
        // Дано
        let repository = FakeVideoGenerationRepository(statuses: [.generating])
        let center = makeCenter(repository: repository)

        // Когда
        _ = try await center.generate(makeRequest(format: .square, photo: TestImage.jpegData(width: 40, height: 30)))
        await waitUntil(center) { $0.first?.remoteID != nil }

        // Тогда
        let uploadedImages = await repository.uploadedImages
        let uploaded = try XCTUnwrap(uploadedImages.first)
        XCTAssertEqual(TestImage.pixelSize(of: uploaded), CGSize(width: 30, height: 30))
    }

    func test_generate_whenServerFails_marksFailed() async throws {
        let center = makeCenter(repository: FakeVideoGenerationRepository(statuses: [.generating, .failed]))

        _ = try await center.generate(makeRequest())
        await waitUntil(center) { $0.first?.state == .failed }

        XCTAssertNil(center.generations.first?.remoteID)
        XCTAssertEqual(center.generations.first?.isNew, false)
        XCTAssertEqual(center.generations.first?.failure, .renderingFailed)
    }

    func test_generate_withoutCredits_recordsTheReason() async throws {
        // Дано
        let repository = FakeVideoGenerationRepository(statuses: [.generating])
        await repository.setStartError(APIError.insufficientCredits)
        let center = makeCenter(repository: repository)

        // Когда
        _ = try await center.generate(makeRequest())
        await waitUntil(center) { $0.first?.state == .failed }

        // Тогда
        XCTAssertEqual(center.generations.first?.failure, .insufficientCredits)
    }

    func test_generate_withUnreadablePhoto_throwsAndAddsNothing() async {
        let center = makeCenter(repository: FakeVideoGenerationRepository(statuses: [.generating]))

        do {
            _ = try await center.generate(makeRequest(photo: Data("not an image".utf8)))
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? ImageCropperError, .unreadableImage)
        }
        XCTAssertTrue(center.generations.isEmpty)
    }

    // MARK: - Retry

    func test_retry_afterFailure_startsNewGeneration() async throws {
        // Дано
        let repository = FakeVideoGenerationRepository(statuses: [.failed])
        let center = makeCenter(repository: repository)
        let id = try await center.generate(makeRequest())
        await waitUntil(center) { $0.first?.state == .failed }
        await repository.setStatuses([.succeeded(videoURL: resultURL)])

        // Когда
        center.retry(id)
        await waitUntil(center) { $0.first?.state == .ready }

        // Тогда
        let startCount = await repository.startCount
        XCTAssertEqual(startCount, 2)
        XCTAssertNil(center.generations.first?.failure)
    }

    // MARK: - Start

    func test_start_resumesPollingWithoutUploadingAgain() async {
        // Дано
        let saved = makeGeneration(state: .inProgress, remoteID: 7)
        let repository = FakeVideoGenerationRepository(statuses: [.succeeded(videoURL: resultURL)])
        let center = makeCenter(repository: repository, library: FakeVideoLibrary(generations: [saved]))

        // Когда
        await center.start().value
        await waitUntil(center) { $0.first?.state == .ready }

        // Тогда
        let startCount = await repository.startCount
        let polledIDs = await repository.polledIDs
        XCTAssertEqual(startCount, 0)
        XCTAssertEqual(polledIDs, [7])
    }

    func test_start_withUnfinishedUpload_marksItFailed() async {
        let saved = makeGeneration(state: .inProgress, remoteID: nil)
        let center = makeCenter(
            repository: FakeVideoGenerationRepository(statuses: [.generating]),
            library: FakeVideoLibrary(generations: [saved])
        )

        await center.start().value

        XCTAssertEqual(center.generations.map(\.state), [.failed])
        XCTAssertEqual(center.generations.first?.failure, .interrupted)
    }

    // MARK: - Mark seen

    func test_markSeen_clearsNewFlag() async {
        let saved = makeGeneration(state: .ready, remoteID: 7, isNew: true)
        let center = makeCenter(
            repository: FakeVideoGenerationRepository(statuses: [.generating]),
            library: FakeVideoLibrary(generations: [saved])
        )
        await center.start().value

        center.markSeen(saved.id)

        XCTAssertEqual(center.generations.first?.isNew, false)
    }

    // MARK: - Private

    private func makeCenter(
        repository: FakeVideoGenerationRepository,
        library: FakeVideoLibrary = FakeVideoLibrary()
    ) -> VideoGenerationCenter {
        let policy = PollingPolicy(
            initialInterval: .milliseconds(1),
            maxInterval: .milliseconds(2),
            backoffFactor: 2,
            timeout: .seconds(5),
            maxConsecutiveFailures: 0
        )
        return VideoGenerationCenter(repository: repository, library: library, poller: Poller(policy: policy))
    }

    private func makeRequest(
        format: VideoFormat = .portrait,
        photo: Data = TestImage.jpegData(width: 30, height: 40)
    ) -> VideoGenerationRequest {
        VideoGenerationRequest(templateID: 1, templateName: "Snowfall", format: format, quality: .p720, photo: photo)
    }

    private func makeGeneration(state: VideoGeneration.State, remoteID: Int?, isNew: Bool = false) -> VideoGeneration {
        VideoGeneration(
            id: UUID(),
            templateID: 1,
            templateName: "Snowfall",
            format: .portrait,
            quality: .p720,
            createdAt: Date(timeIntervalSince1970: 0),
            state: state,
            remoteID: remoteID,
            isNew: isNew
        )
    }

    private func waitUntil(
        _ center: VideoGenerationCenter,
        _ condition: @escaping ([VideoGeneration]) -> Bool
    ) async {
        let expectation = expectation(description: "Generations match the condition")
        let cancellable = center.generationsPublisher
            .first(where: condition)
            .sink { _ in expectation.fulfill() }
        await fulfillment(of: [expectation], timeout: 2)
        cancellable.cancel()
    }
}
