import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: PodWatchViewModel

    private let noSelectionTag = "__none__"

    var body: some View {
        Form {
            Section("AirPods Device") {
                if viewModel.devices.isEmpty {
                    Text("No AirPods-like devices discovered yet. PodWatch refreshes automatically using the poll interval below.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Picker("Monitor", selection: deviceSelectionBinding) {
                    Text("Select a device").tag(noSelectionTag)
                    ForEach(viewModel.devices) { device in
                        Text(device.displayLabel).tag(device.address)
                    }
                }
                .labelsHidden()

                if let selectedSnapshot = viewModel.selectedSnapshot {
                    Text(selectedSnapshot.compactStatus)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Section("Thresholds") {
                Stepper(value: lowThresholdBinding, in: 0...99) {
                    LabeledContent("Low threshold") {
                        Text("\(viewModel.lowThreshold)%")
                    }
                }

                Stepper(value: chargedThresholdBinding, in: (viewModel.lowThreshold + 1)...100) {
                    LabeledContent("Charged threshold") {
                        Text("\(viewModel.chargedThreshold)%")
                    }
                }

                Text("Low reminders fire once when a bud crosses below the low threshold. Charged reminders fire once when it later reaches the charged threshold.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Overlay") {
                Stepper(value: overlayDurationBinding, in: 1...30) {
                    LabeledContent("Duration") {
                        Text("\(viewModel.overlayDurationSeconds)s")
                    }
                }

                Text("Reminders appear centered on the active screen and dismiss automatically without taking focus.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Monitoring") {
                Stepper(value: pollIntervalBinding, in: 5...300, step: 5) {
                    LabeledContent("Poll interval") {
                        Text("\(viewModel.pollIntervalSeconds)s")
                    }
                }

                Text("PodWatch refreshes battery levels on this interval. Lower values react faster but wake the helper process more often.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                Button("Reset All Settings to Defaults") {
                    viewModel.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 560)
    }

    private var deviceSelectionBinding: Binding<String> {
        Binding(
            get: { viewModel.selectedDeviceAddress ?? noSelectionTag },
            set: { newValue in
                viewModel.selectDevice(address: newValue == noSelectionTag ? nil : newValue)
            }
        )
    }

    private var lowThresholdBinding: Binding<Int> {
        Binding(
            get: { viewModel.lowThreshold },
            set: { viewModel.setLowThreshold($0) }
        )
    }

    private var chargedThresholdBinding: Binding<Int> {
        Binding(
            get: { viewModel.chargedThreshold },
            set: { viewModel.setChargedThreshold($0) }
        )
    }

    private var overlayDurationBinding: Binding<Int> {
        Binding(
            get: { viewModel.overlayDurationSeconds },
            set: { viewModel.setOverlayDuration($0) }
        )
    }

    private var pollIntervalBinding: Binding<Int> {
        Binding(
            get: { viewModel.pollIntervalSeconds },
            set: { viewModel.setPollInterval($0) }
        )
    }
}
