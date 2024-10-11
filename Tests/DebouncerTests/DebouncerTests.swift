import Testing
@testable import Debouncer
import XCTest


final class AccumulatingDebouncerTests: XCTestCase {

    func testAccumulate() throws {

        var firstOutput: [Int] = []
        let firstDebounceCall = expectation(description: "debounce call made")
        firstDebounceCall.expectedFulfillmentCount = 1
        let debouncer = AccumulatingDebouncer<[Int]>(initialBufferValue: [0])
        let startTime = Date()
        debouncer.debounce(
            for: 1.0,
            accumulate: { $0.append(1) }) {
                firstOutput = $0
                firstDebounceCall.fulfill()
            }
        debouncer.debounce(for: 1.0,
                           accumulate: { $0.append(2)}) {
            firstOutput = $0
            firstDebounceCall.fulfill()
        }

        wait(for: [firstDebounceCall], timeout: 3)
        let timeElapsed = startTime.distance(to: Date())
        // make sure it's been more than 1 seconds
        XCTAssert(timeElapsed >= 1)
        XCTAssertEqual(firstOutput, [0, 1, 2])

        var secondOutput: [Int] = []
        let secondDebounceCall = expectation(description: "second debounce call made")
        secondDebounceCall.expectedFulfillmentCount = 1
        debouncer.debounce(for: 1, accumulate: { $0.append(3)}) {
            secondOutput = $0
            secondDebounceCall.fulfill()
        }
        wait(for: [secondDebounceCall], timeout: 3)
        XCTAssertEqual(secondOutput, [0,     3])
    }
}
