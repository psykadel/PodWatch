import SwiftUI

@main
struct PodWatchApp: App {
    private let viewModel = PodWatchViewModel()

    init() {
        viewModel.start()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(viewModel)
        } label: {
            MenuBarIconView()
                .frame(width: 18, height: 18)
                .foregroundStyle(.primary)
                .accessibilityLabel("PodWatch")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(viewModel)
        }
    }
}
