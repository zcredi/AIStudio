import XCTest
@testable import AIStudio

final class PollerTests: XCTestCase {
    /// Проигрывает заданные исходы, по одному на проверку, и считает проверки.
    private actor ScriptedCheck {
        enum Outcome: Sendable {
            case pending
            case value(Int)
            case failure
        }

        private(set) var callCount = 0
        private var outcomes: [Outcome]

        init(_ outcomes: [Outcome]) {
            self.outcomes = outcomes
        }

        func run() throws -> Int? {
            callCount += 1
            let outcome = outcomes.isEmpty ? .pending : outcomes.removeFirst()
            switch outcome {
            case .pending:
                return nil
            case .value(let value):
                return value
            case .failure:
                throw APIError.offline
            }
        }
    }

    func test_poll_whenValueArrives_returnsIt() async throws {
        // Дано
        let check = ScriptedCheck([.pending, .pending, .value(7)])

        // Когда
        let value = try await makePoller().poll { try await check.run() }

        // Тогда
        XCTAssertEqual(value, 7)
        let callCount = await check.callCount
        XCTAssertEqual(callCount, 3)
    }

    func test_poll_whenNeverReady_timesOut() async {
        let check = ScriptedCheck([])

        do {
            _ = try await makePoller(timeout: .milliseconds(30)).poll { try await check.run() }
            XCTFail("Expected a timeout")
        } catch {
            XCTAssertEqual(error as? PollingError, .timedOut)
        }
    }

    func test_poll_withFewFailuresInARow_keepsPolling() async throws {
        let check = ScriptedCheck([.failure, .failure, .pending, .failure, .failure, .value(1)])

        let value = try await makePoller(maxConsecutiveFailures: 2).poll { try await check.run() }

        XCTAssertEqual(value, 1)
    }

    func test_poll_withTooManyFailuresInARow_throwsLastError() async {
        let check = ScriptedCheck([.failure, .failure, .failure])

        do {
            _ = try await makePoller(maxConsecutiveFailures: 2).poll { try await check.run() }
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, .offline)
        }
    }

    func test_poll_whenCancelled_throwsCancellation() async {
        // Дано
        let check = ScriptedCheck([])
        let poller = makePoller(timeout: .seconds(10))

        // Когда
        let task = Task { try await poller.poll { try await check.run() } }
        task.cancel()

        // Тогда
        let result = await task.result
        XCTAssertThrowsError(try result.get()) { XCTAssertTrue($0 is CancellationError) }
        let callCount = await check.callCount
        XCTAssertLessThanOrEqual(callCount, 1)
    }

    // MARK: - Private

    private func makePoller(
        interval: Duration = .milliseconds(1),
        timeout: Duration = .seconds(1),
        maxConsecutiveFailures: Int = 0
    ) -> Poller {
        Poller(policy: PollingPolicy(
            initialInterval: interval,
            maxInterval: interval * 2,
            backoffFactor: 2,
            timeout: timeout,
            maxConsecutiveFailures: maxConsecutiveFailures
        ))
    }
}
