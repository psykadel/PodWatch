import AppKit
import SwiftUI

@MainActor
final class OverlayPresenter {
    private struct QueueItem {
        let event: ReminderEvent
        let duration: TimeInterval
    }

    private var queue: [QueueItem] = []
    private var panel: OverlayPanel?
    private var dismissalTask: Task<Void, Never>?
    private var isPresenting = false

    func enqueue(_ event: ReminderEvent, duration: TimeInterval) {
        queue.append(QueueItem(event: event, duration: duration))
        presentNextIfNeeded()
    }

    func dismissAll() {
        dismissalTask?.cancel()
        dismissalTask = nil
        queue.removeAll()
        isPresenting = false
        panel?.orderOut(nil)
    }

    private func presentNextIfNeeded() {
        guard !isPresenting, let nextItem = queue.first else {
            return
        }

        let panel = panel ?? makePanel()
        let hostingController = NSHostingController(rootView: ReminderOverlayView(event: nextItem.event))
        panel.contentViewController = hostingController

        let fittingSize = hostingController.view.fittingSize
        let contentSize = NSSize(width: max(360, min(460, fittingSize.width)), height: max(150, min(220, fittingSize.height)))
        panel.setContentSize(contentSize)
        center(panel: panel, contentSize: contentSize)
        panel.orderFrontRegardless()

        isPresenting = true
        dismissalTask?.cancel()
        dismissalTask = Task {
            let duration = max(nextItem.duration, 1)
            try? await Task.sleep(for: .seconds(duration))
            await MainActor.run {
                self.advanceQueue()
            }
        }
    }

    private func advanceQueue() {
        if !queue.isEmpty {
            queue.removeFirst()
        }

        isPresenting = false
        panel?.orderOut(nil)
        presentNextIfNeeded()
    }

    private func makePanel() -> OverlayPanel {
        let panel = OverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 160),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        self.panel = panel
        return panel
    }

    private func center(panel: NSPanel, contentSize: NSSize) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main
        let frame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(
            x: frame.midX - (contentSize.width / 2),
            y: frame.midY - (contentSize.height / 2)
        )
        panel.setFrame(NSRect(origin: origin, size: contentSize), display: true)
    }
}

private final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
