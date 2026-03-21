import XCTest
@testable import PodWatch

final class ReminderEngineTests: XCTestCase {
    func testLeftBudCrossingBelowThresholdProducesLowReminder() {
        var engine = ReminderEngine()

        XCTAssertTrue(engine.process(snapshot: snapshot(left: 18, right: 18), lowThreshold: 5, chargedThreshold: 33).isEmpty)

        let events = engine.process(snapshot: snapshot(left: 5, right: 18), lowThreshold: 5, chargedThreshold: 33)

        XCTAssertEqual(events, [ReminderEvent(kind: .low, sides: [.left], deviceName: "Desk AirPods")])
    }

    func testRightBudCrossingBelowThresholdProducesLowReminder() {
        var engine = ReminderEngine()

        XCTAssertTrue(engine.process(snapshot: snapshot(left: 18, right: 18), lowThreshold: 5, chargedThreshold: 33).isEmpty)

        let events = engine.process(snapshot: snapshot(left: 18, right: 4), lowThreshold: 5, chargedThreshold: 33)

        XCTAssertEqual(events, [ReminderEvent(kind: .low, sides: [.right], deviceName: "Desk AirPods")])
    }

    func testBothBudsCrossingBelowThresholdAggregateIntoOneReminder() {
        var engine = ReminderEngine()

        XCTAssertTrue(engine.process(snapshot: snapshot(left: 20, right: 20), lowThreshold: 5, chargedThreshold: 33).isEmpty)

        let events = engine.process(snapshot: snapshot(left: 5, right: 3), lowThreshold: 5, chargedThreshold: 33)

        XCTAssertEqual(events, [ReminderEvent(kind: .low, sides: [.left, .right], deviceName: "Desk AirPods")])
    }

    func testLowReminderDoesNotRepeatWhileStillLow() {
        var engine = ReminderEngine()

        XCTAssertTrue(engine.process(snapshot: snapshot(left: 20, right: 20), lowThreshold: 5, chargedThreshold: 33).isEmpty)
        XCTAssertEqual(engine.process(snapshot: snapshot(left: 5, right: 20), lowThreshold: 5, chargedThreshold: 33).count, 1)

        let repeatedEvents = engine.process(snapshot: snapshot(left: 3, right: 20), lowThreshold: 5, chargedThreshold: 33)

        XCTAssertTrue(repeatedEvents.isEmpty)
    }

    func testLowToMidRecoveryDoesNotRepeatUntilChargedThreshold() {
        var engine = ReminderEngine()

        XCTAssertTrue(engine.process(snapshot: snapshot(left: 12, right: 12), lowThreshold: 5, chargedThreshold: 33).isEmpty)
        XCTAssertEqual(engine.process(snapshot: snapshot(left: 4, right: 12), lowThreshold: 5, chargedThreshold: 33).count, 1)

        let midRangeEvents = engine.process(snapshot: snapshot(left: 12, right: 12), lowThreshold: 5, chargedThreshold: 33)

        XCTAssertTrue(midRangeEvents.isEmpty)
    }

    func testChargedReminderFiresExactlyOnceWhenThresholdIsReached() {
        var engine = ReminderEngine()

        XCTAssertTrue(engine.process(snapshot: snapshot(left: 12, right: 12), lowThreshold: 5, chargedThreshold: 33).isEmpty)
        XCTAssertEqual(engine.process(snapshot: snapshot(left: 4, right: 12), lowThreshold: 5, chargedThreshold: 33).count, 1)
        XCTAssertTrue(engine.process(snapshot: snapshot(left: 20, right: 12), lowThreshold: 5, chargedThreshold: 33).isEmpty)

        let chargedEvents = engine.process(snapshot: snapshot(left: 33, right: 12), lowThreshold: 5, chargedThreshold: 33)
        let repeatedChargedEvents = engine.process(snapshot: snapshot(left: 70, right: 12), lowThreshold: 5, chargedThreshold: 33)

        XCTAssertEqual(chargedEvents, [ReminderEvent(kind: .charged, sides: [.left], deviceName: "Desk AirPods")])
        XCTAssertTrue(repeatedChargedEvents.isEmpty)
    }

    func testMixedLowAndChargedEventsReturnLowBeforeCharged() {
        var engine = ReminderEngine()

        XCTAssertTrue(engine.process(snapshot: snapshot(left: 12, right: 12), lowThreshold: 5, chargedThreshold: 33).isEmpty)
        XCTAssertEqual(engine.process(snapshot: snapshot(left: 4, right: 12), lowThreshold: 5, chargedThreshold: 33).count, 1)

        let events = engine.process(snapshot: snapshot(left: 40, right: 5), lowThreshold: 5, chargedThreshold: 33)

        XCTAssertEqual(events, [
            ReminderEvent(kind: .low, sides: [.right], deviceName: "Desk AirPods"),
            ReminderEvent(kind: .charged, sides: [.left], deviceName: "Desk AirPods")
        ])
    }

    private func snapshot(left: Int?, right: Int?, isConnected: Bool = true) -> BluetoothDeviceSnapshot {
        BluetoothDeviceSnapshot(
            name: "Desk AirPods",
            address: "11-22-33-44-55-66",
            isConnected: isConnected,
            leftBattery: left,
            rightBattery: right,
            caseBattery: 80,
            mainBattery: nil
        )
    }
}
