import XCTest
@testable import AIStudio

@MainActor
final class GeneratingViewModelTests: XCTestCase {
    func test_whenGenerationFails_explainsWhy() {
        let generation = VideoGeneration.fixture(state: .inProgress)
        let generator = FakeVideoGenerator(generations: [generation])
        let viewModel = GeneratingViewModel(generationID: generation.id, generator: generator, premiumGate: FakePremiumGate())
        viewModel.start()

        var failed = VideoGeneration.fixture(id: generation.id, state: .failed)
        failed.failure = .insufficientCredits
        generator.send([failed])

        let message = VideoGenerationError.insufficientCredits.localizedDescription
        XCTAssertEqual(viewModel.state, .failed(UserFacingError(message: message)))
    }

    func test_whenGenerationIsReady_opensResultOnce() {
        // Дано
        let generation = VideoGeneration.fixture(state: .inProgress)
        let generator = FakeVideoGenerator(generations: [generation])
        let viewModel = GeneratingViewModel(generationID: generation.id, generator: generator, premiumGate: FakePremiumGate())
        let events = PublisherRecorder(viewModel.events)
        viewModel.start()

        // Когда
        let ready = VideoGeneration.fixture(id: generation.id, state: .ready, isNew: true)
        generator.send([ready])
        generator.send([ready])

        // Тогда
        XCTAssertEqual(events.values, [.openResult(ready)])
    }

    func test_retry_restartsGeneration() {
        let generation = VideoGeneration.fixture(state: .failed)
        let generator = FakeVideoGenerator(generations: [generation])
        let viewModel = GeneratingViewModel(generationID: generation.id, generator: generator, premiumGate: FakePremiumGate())

        viewModel.retryTapped()

        XCTAssertEqual(generator.retriedIDs, [generation.id])
    }
}
