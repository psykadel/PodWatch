import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var viewModel: PodWatchViewModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                MenuBarIconView()
                    .frame(width: 24, height: 20)
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 0) {
                    Text("PodWatch")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }

            Divider()

            statusSection

            if let lastErrorMessage = viewModel.lastErrorMessage {
                Text(lastErrorMessage)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Button("Settings…") {
                showSettings()
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Quit PodWatch") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(14)
        .frame(width: 330)
    }

    @ViewBuilder
    private var statusSection: some View {
        if let snapshot = viewModel.selectedSnapshot {
            VStack(alignment: .leading, spacing: 10) {
                deviceHeading(name: snapshot.name, address: snapshot.address)
                thresholdSummary
                statusRow(label: "Connection", value: snapshot.isConnected ? "Connected" : "Disconnected")
                statusRow(label: "Left", value: formattedBattery(snapshot.leftBattery))
                statusRow(label: "Right", value: formattedBattery(snapshot.rightBattery))
                statusRow(label: "Case", value: formattedBattery(snapshot.caseBattery))
            }
        } else if let selectedDeviceName = viewModel.selectedDeviceName {
            VStack(alignment: .leading, spacing: 8) {
                deviceHeading(name: selectedDeviceName, address: viewModel.selectedDeviceAddress)
                thresholdSummary
                Text("Selected device is currently unavailable. PodWatch keeps polling every \(viewModel.pollIntervalSeconds) seconds.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("No AirPods selected")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                thresholdSummary
                Text("Open Settings to choose the AirPods device you want PodWatch to monitor.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func deviceHeading(name: String, address: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.system(size: 15, weight: .semibold, design: .rounded))

            if let address {
                Text(address)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var thresholdSummary: some View {
        HStack(spacing: 8) {
            thresholdPill(
                title: "Low",
                value: "\(viewModel.lowThreshold)%",
                systemImage: "arrow.down.circle.fill",
                tint: .orange
            )
            thresholdPill(
                title: "Ready",
                value: "\(viewModel.chargedThreshold)%",
                systemImage: "checkmark.circle.fill",
                tint: .green
            )
        }
    }

    private func thresholdPill(title: String, value: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
            Text("\(title) \(value)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.12))
        )
    }

    private func statusRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
    }

    private func formattedBattery(_ value: Int?) -> String {
        guard let value else {
            return "—"
        }

        return "\(value)%"
    }

    private func showSettings() {
        openSettings()

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)

            let settingsWindow = NSApp.windows.first {
                $0.title.localizedCaseInsensitiveContains("settings")
            }

            for window in NSApp.windows where window !== settingsWindow && window.isVisible {
                window.orderOut(nil)
            }

            settingsWindow?.makeKeyAndOrderFront(nil)
            settingsWindow?.orderFrontRegardless()
        }
    }
}
