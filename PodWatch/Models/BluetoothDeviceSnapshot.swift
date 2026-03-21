import Foundation

enum BudSide: String, CaseIterable, Comparable {
    case left
    case right

    var title: String {
        rawValue.capitalized
    }

    static func < (lhs: BudSide, rhs: BudSide) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    private var sortOrder: Int {
        switch self {
        case .left:
            return 0
        case .right:
            return 1
        }
    }
}

enum ReminderKind: String {
    case low
    case charged
}

struct BluetoothDeviceSnapshot: Identifiable, Equatable, Hashable {
    let name: String
    let address: String
    let isConnected: Bool
    let leftBattery: Int?
    let rightBattery: Int?
    let caseBattery: Int?
    let mainBattery: Int?

    var id: String {
        address
    }

    var displayLabel: String {
        guard name.caseInsensitiveCompare(address) != .orderedSame else {
            return address
        }

        return "\(name) (\(address))"
    }

    var isEligibleAirPodsCandidate: Bool {
        let normalizedName = name.lowercased()
        return normalizedName.contains("airpods")
            || leftBattery != nil
            || rightBattery != nil
            || mainBattery != nil
    }

    var compactStatus: String {
        let parts = [
            formattedBattery(label: "L", value: leftBattery),
            formattedBattery(label: "R", value: rightBattery),
            formattedBattery(label: "Case", value: caseBattery)
        ].compactMap { $0 }

        if parts.isEmpty, let mainBattery {
            return "Battery \(mainBattery)%"
        }

        return parts.isEmpty ? "No live battery data" : parts.joined(separator: "  ")
    }

    func battery(for side: BudSide) -> Int? {
        switch side {
        case .left:
            return leftBattery
        case .right:
            return rightBattery
        }
    }

    private func formattedBattery(label: String, value: Int?) -> String? {
        guard let value else {
            return nil
        }

        return "\(label) \(value)%"
    }
}

struct ReminderEvent: Identifiable, Equatable {
    let kind: ReminderKind
    let sides: [BudSide]
    let deviceName: String

    var id: String {
        "\(kind.rawValue)-\(deviceName)-\(sides.map(\.rawValue).joined(separator: "-"))"
    }

    var title: String {
        switch (kind, sides) {
        case (.low, [.left]):
            return "Charge left AirPod"
        case (.low, [.right]):
            return "Charge right AirPod"
        case (.low, _):
            return "Charge both AirPods"
        case (.charged, [.left]):
            return "Left AirPod charged"
        case (.charged, [.right]):
            return "Right AirPod charged"
        case (.charged, _):
            return "Both AirPods charged"
        }
    }

    var subtitle: String {
        switch kind {
        case .low:
            return "\(deviceName) dropped below your low threshold."
        case .charged:
            return "\(deviceName) is ready to swap back in."
        }
    }
}
