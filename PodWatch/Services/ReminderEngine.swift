import Foundation

struct ReminderEngine {
    private var states: [BudKey: BudTrackingState] = [:]

    mutating func reset() {
        states.removeAll()
    }

    mutating func process(snapshot: BluetoothDeviceSnapshot?, lowThreshold: Int, chargedThreshold: Int) -> [ReminderEvent] {
        guard let snapshot, snapshot.isConnected else {
            return []
        }

        let thresholds = AppConfiguration.normalizedThresholds(low: lowThreshold, charged: chargedThreshold)
        var lowSides: [BudSide] = []
        var chargedSides: [BudSide] = []

        for side in BudSide.allCases {
            let key = BudKey(deviceAddress: snapshot.address, side: side)
            var state = states[key] ?? BudTrackingState()
            let currentBattery = snapshot.battery(for: side)

            guard let currentBattery else {
                state.lastBattery = nil
                states[key] = state
                continue
            }

            if let previousBattery = state.lastBattery {
                if !state.isArmedForCharged && previousBattery > thresholds.low && currentBattery <= thresholds.low {
                    lowSides.append(side)
                    state.isArmedForCharged = true
                } else if state.isArmedForCharged && previousBattery < thresholds.charged && currentBattery >= thresholds.charged {
                    chargedSides.append(side)
                    state.isArmedForCharged = false
                }
            } else if currentBattery <= thresholds.low {
                state.isArmedForCharged = true
            }

            state.lastBattery = currentBattery
            states[key] = state
        }

        var events: [ReminderEvent] = []

        if !lowSides.isEmpty {
            events.append(ReminderEvent(kind: .low, sides: lowSides.sorted(), deviceName: snapshot.name))
        }

        if !chargedSides.isEmpty {
            events.append(ReminderEvent(kind: .charged, sides: chargedSides.sorted(), deviceName: snapshot.name))
        }

        return events
    }
}

private struct BudKey: Hashable {
    let deviceAddress: String
    let side: BudSide
}

private struct BudTrackingState {
    var lastBattery: Int?
    var isArmedForCharged = false
}
