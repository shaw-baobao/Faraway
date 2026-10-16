import XCTest
@testable import RestCore
final class RestClockTests: XCTestCase {
    func testFullCycleAndNoPrematureCompletion() {
        var clock = RestClock(now: 0)
        clock.tick(at: 1199)
        XCTAssertEqual(clock.phase, .working)
        clock.tick(at: 1200)
        XCTAssertEqual(clock.phase, .resting)
        clock.tick(at: 1219)
        XCTAssertEqual(clock.completed, 0)
        clock.tick(at: 1220)
        XCTAssertEqual(clock.completed, 1)
        XCTAssertEqual(clock.deadline, 2420)
    }
    func testPausePreservesRemainingTime() {
        var clock = RestClock(now: 0)
        clock.togglePause(at: 100)
        clock.tick(at: 5000)
        XCTAssertEqual(clock.remaining(at: 5000), 1100)
        clock.togglePause(at: 5000)
        XCTAssertEqual(clock.deadline, 6100)
    }
    func testSnoozeDoesNotCountBreak() {
        var clock = RestClock(now: 0)
        clock.startBreak(at: 10)
        clock.snooze(at: 15)
        XCTAssertEqual(clock.completed, 0)
        XCTAssertEqual(clock.deadline, 315)
    }
    func testSleepCancelsBreakWithoutCredit() {
        var clock = RestClock(now: 0)
        clock.startBreak(at: 10)
        clock.suspend(at: 15)
        clock.tick(at: 10000)
        XCTAssertEqual(clock.phase, .paused)
        XCTAssertEqual(clock.completed, 0)
        clock.togglePause(at: 10000)
        XCTAssertEqual(clock.remaining(at: 10000), 1200)
    }
    func testDelayedTickStartsFreshBreak() {
        var clock = RestClock(now: 0)
        clock.tick(at: 6000)
        XCTAssertEqual(clock.phase, .resting)
        XCTAssertEqual(clock.remaining(at: 6000), 20)
        XCTAssertEqual(clock.completed, 0)
    }
}
