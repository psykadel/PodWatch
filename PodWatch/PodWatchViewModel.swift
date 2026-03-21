import Combine
import Foundation

@MainActor
final class PodWatchViewModel: ObservableObject {
    @Published private(set) var devices: [BluetoothDeviceSnapshot] = []
    @Published private(set) var selectedSnapshot: BluetoothDeviceSnapshot?
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var selectedDeviceAddress: String?
    @Published private(set) var selectedDeviceName: String?
    @Published private(set) var lowThreshold: Int
    @Published private(set) var chargedThreshold: Int
    @Published private(set) var overlayDurationSeconds: Int
    @Published private(set) var pollIntervalSeconds: Int

    private let defaults: UserDefaults
    private let batteryProvider: BluetoothBatteryProviding
    private let overlayPresenter: OverlayPresenter

    private var reminderEngine = ReminderEngine()
    private var pollingTask: Task<Void, Never>?
    private var isPolling = false

    init(
        defaults: UserDefaults = .standard,
        batteryProvider: BluetoothBatteryProviding = BluetoothBatteryProvider(),
        overlayPresenter: OverlayPresenter? = nil
    ) {
        self.defaults = defaults
        self.batteryProvider = batteryProvider
        self.overlayPresenter = overlayPresenter ?? OverlayPresenter()

        let configuration = AppConfiguration(
            selectedDeviceAddress: defaults.string(forKey: DefaultsKeys.selectedDeviceAddress),
            selectedDeviceName: defaults.string(forKey: DefaultsKeys.selectedDeviceName),
            lowThreshold: defaults.object(forKey: DefaultsKeys.lowThreshold) as? Int ?? AppConfiguration.defaultLowThreshold,
            chargedThreshold: defaults.object(forKey: DefaultsKeys.chargedThreshold) as? Int ?? AppConfiguration.defaultChargedThreshold,
            overlayDurationSeconds: defaults.object(forKey: DefaultsKeys.overlayDurationSeconds) as? Int ?? AppConfiguration.defaultOverlayDurationSeconds,
            pollIntervalSeconds: defaults.object(forKey: DefaultsKeys.pollIntervalSeconds) as? Int ?? AppConfiguration.defaultPollIntervalSeconds
        )

        self.selectedDeviceAddress = configuration.selectedDeviceAddress
        self.selectedDeviceName = configuration.selectedDeviceName
        self.lowThreshold = configuration.lowThreshold
        self.chargedThreshold = configuration.chargedThreshold
        self.overlayDurationSeconds = configuration.overlayDurationSeconds
        self.pollIntervalSeconds = configuration.pollIntervalSeconds
    }

    deinit {
        pollingTask?.cancel()
    }

    func start() {
        guard pollingTask == nil else {
            return
        }

        pollingTask = Task {
            while !Task.isCancelled {
                let startedAt = ContinuousClock.now
                await refreshSnapshots()
                let elapsed = startedAt.duration(to: .now)
                let remaining = Duration.seconds(pollIntervalSeconds) - elapsed

                if remaining > .zero {
                    try? await Task.sleep(for: remaining)
                }
            }
        }
    }

    func selectDevice(address: String?) {
        guard let address else {
            selectedDeviceAddress = nil
            selectedDeviceName = nil
            selectedSnapshot = nil
            overlayPresenter.dismissAll()
            reminderEngine.reset()
            persistSelection()
            return
        }

        guard let device = devices.first(where: { $0.address == address }) else {
            return
        }

        selectedDeviceAddress = device.address
        selectedDeviceName = device.name
        selectedSnapshot = device
        reminderEngine.reset()
        persistSelection()
    }

    func setLowThreshold(_ value: Int) {
        let thresholds = AppConfiguration.normalizedThresholds(low: value, charged: chargedThreshold)
        lowThreshold = thresholds.low
        chargedThreshold = thresholds.charged
        reminderEngine.reset()
        persistThresholds()
    }

    func setChargedThreshold(_ value: Int) {
        let thresholds = AppConfiguration.normalizedThresholds(low: lowThreshold, charged: value)
        lowThreshold = thresholds.low
        chargedThreshold = thresholds.charged
        reminderEngine.reset()
        persistThresholds()
    }

    func setOverlayDuration(_ seconds: Int) {
        overlayDurationSeconds = AppConfiguration.clampOverlayDuration(seconds)
        defaults.set(overlayDurationSeconds, forKey: DefaultsKeys.overlayDurationSeconds)
    }

    func setPollInterval(_ seconds: Int) {
        pollIntervalSeconds = AppConfiguration.clampPollInterval(seconds)
        defaults.set(pollIntervalSeconds, forKey: DefaultsKeys.pollIntervalSeconds)
    }

    func resetToDefaults() {
        selectedDeviceAddress = nil
        selectedDeviceName = nil
        selectedSnapshot = nil
        lowThreshold = AppConfiguration.defaultLowThreshold
        chargedThreshold = AppConfiguration.defaultChargedThreshold
        overlayDurationSeconds = AppConfiguration.defaultOverlayDurationSeconds
        pollIntervalSeconds = AppConfiguration.defaultPollIntervalSeconds

        overlayPresenter.dismissAll()
        reminderEngine.reset()

        persistSelection()
        persistThresholds()
        defaults.set(overlayDurationSeconds, forKey: DefaultsKeys.overlayDurationSeconds)
        defaults.set(pollIntervalSeconds, forKey: DefaultsKeys.pollIntervalSeconds)
    }

    private func refreshSnapshots() async {
        guard !isPolling else {
            return
        }

        isPolling = true
        defer { isPolling = false }

        do {
            let allSnapshots = try await batteryProvider.fetchSnapshots()
            applySnapshots(allSnapshots)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func applySnapshots(_ allSnapshots: [BluetoothDeviceSnapshot]) {
        let eligibleDevices = allSnapshots.filter(\.isEligibleAirPodsCandidate)
        devices = eligibleDevices

        if selectedDeviceAddress == nil, eligibleDevices.count == 1, let autoSelectedDevice = eligibleDevices.first {
            selectedDeviceAddress = autoSelectedDevice.address
            selectedDeviceName = autoSelectedDevice.name
            reminderEngine.reset()
            persistSelection()
        }

        if let selectedDeviceAddress {
            selectedSnapshot = eligibleDevices.first(where: { $0.address == selectedDeviceAddress })
            if let selectedSnapshot {
                selectedDeviceName = selectedSnapshot.name
                persistSelection()
            }
        } else {
            selectedSnapshot = nil
        }

        guard let selectedSnapshot else {
            return
        }

        let events = reminderEngine.process(
            snapshot: selectedSnapshot,
            lowThreshold: lowThreshold,
            chargedThreshold: chargedThreshold
        )

        for event in events {
            overlayPresenter.enqueue(event, duration: TimeInterval(overlayDurationSeconds))
        }
    }

    private func persistSelection() {
        persist(selectedDeviceAddress, forKey: DefaultsKeys.selectedDeviceAddress)
        persist(selectedDeviceName, forKey: DefaultsKeys.selectedDeviceName)
    }

    private func persistThresholds() {
        defaults.set(lowThreshold, forKey: DefaultsKeys.lowThreshold)
        defaults.set(chargedThreshold, forKey: DefaultsKeys.chargedThreshold)
    }

    private func persist(_ string: String?, forKey key: String) {
        if let string {
            defaults.set(string, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}

private enum DefaultsKeys {
    static let selectedDeviceAddress = "selectedDeviceAddress"
    static let selectedDeviceName = "selectedDeviceName"
    static let lowThreshold = "lowThreshold"
    static let chargedThreshold = "chargedThreshold"
    static let overlayDurationSeconds = "overlayDurationSeconds"
    static let pollIntervalSeconds = "pollIntervalSeconds"
}
