import Foundation

struct AppConfiguration: Equatable {
    static let defaultLowThreshold = 5
    static let defaultChargedThreshold = 33
    static let defaultOverlayDurationSeconds = 5
    static let defaultPollIntervalSeconds = 30

    var selectedDeviceAddress: String?
    var selectedDeviceName: String?
    var lowThreshold: Int
    var chargedThreshold: Int
    var overlayDurationSeconds: Int
    var pollIntervalSeconds: Int

    init(
        selectedDeviceAddress: String? = nil,
        selectedDeviceName: String? = nil,
        lowThreshold: Int = Self.defaultLowThreshold,
        chargedThreshold: Int = Self.defaultChargedThreshold,
        overlayDurationSeconds: Int = Self.defaultOverlayDurationSeconds,
        pollIntervalSeconds: Int = Self.defaultPollIntervalSeconds
    ) {
        let thresholds = Self.normalizedThresholds(low: lowThreshold, charged: chargedThreshold)
        self.selectedDeviceAddress = selectedDeviceAddress
        self.selectedDeviceName = selectedDeviceName
        self.lowThreshold = thresholds.low
        self.chargedThreshold = thresholds.charged
        self.overlayDurationSeconds = Self.clampOverlayDuration(overlayDurationSeconds)
        self.pollIntervalSeconds = Self.clampPollInterval(pollIntervalSeconds)
    }

    static func normalizedThresholds(low: Int, charged: Int) -> (low: Int, charged: Int) {
        var low = min(max(low, 0), 100)
        var charged = min(max(charged, 0), 100)

        if low == 100 {
            low = 99
        }

        if charged <= low {
            charged = min(100, low + 1)
        }

        if charged <= low {
            low = max(0, charged - 1)
        }

        return (low, charged)
    }

    static func clampOverlayDuration(_ seconds: Int) -> Int {
        min(max(seconds, 1), 30)
    }

    static func clampPollInterval(_ seconds: Int) -> Int {
        min(max(seconds, 5), 300)
    }
}
