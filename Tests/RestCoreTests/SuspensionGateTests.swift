import XCTest
@testable import RestCore

final class SuspensionGateTests: XCTestCase {
    func testDisplayWakeDoesNotResumeInactiveSession() {
        var gate = SuspensionGate()
        XCTAssertTrue(gate.begin(.session, wasRunning: true))
        XCTAssertFalse(gate.begin(.display, wasRunning: false))
        XCTAssertFalse(gate.begin(.system, wasRunning: false))
        XCTAssertFalse(gate.end(.system))
        XCTAssertFalse(gate.end(.display))
        XCTAssertTrue(gate.end(.session))
        XCTAssertFalse(gate.end(.session))
    }

    func testManualPauseSurvivesSleep() {
        var gate = SuspensionGate()
        XCTAssertTrue(gate.begin(.system, wasRunning: false))
        XCTAssertFalse(gate.end(.system))
    }

    func testDuplicateAndUnmatchedNotifications() {
        var gate = SuspensionGate()
        XCTAssertFalse(gate.end(.display))
        XCTAssertTrue(gate.begin(.display, wasRunning: true))
        XCTAssertFalse(gate.begin(.display, wasRunning: false))
        XCTAssertTrue(gate.end(.display))
        XCTAssertTrue(gate.begin(.system, wasRunning: false))
        XCTAssertFalse(gate.end(.system))
    }
}
