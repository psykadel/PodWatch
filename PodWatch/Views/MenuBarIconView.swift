import AppKit
import SwiftUI

private enum MenuBarIconImageProvider {
    static let menuBarImage: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()

        NSColor.labelColor.setFill()
        NSColor.labelColor.setStroke()

        let batteryBody = NSBezierPath(roundedRect: NSRect(x: 1.6, y: 3.1, width: 7.4, height: 11.8), xRadius: 2.2, yRadius: 2.2)
        batteryBody.lineWidth = 1.55
        batteryBody.stroke()

        let batteryCap = NSBezierPath(roundedRect: NSRect(x: 3.95, y: 15.1, width: 2.7, height: 1.0), xRadius: 0.3, yRadius: 0.3)
        batteryCap.fill()

        let chargeBar = NSBezierPath(roundedRect: NSRect(x: 3.5, y: 5.8, width: 3.6, height: 6.2), xRadius: 1.1, yRadius: 1.1)
        chargeBar.fill()

        let budHead = NSBezierPath(ovalIn: NSRect(x: 10.8, y: 8.5, width: 5.5, height: 5.5))
        budHead.fill()

        let budStem = NSBezierPath(roundedRect: NSRect(x: 12.8, y: 2.6, width: 2.05, height: 7.4), xRadius: 1.0, yRadius: 1.0)
        budStem.fill()

        image.unlockFocus()
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }()
}

struct MenuBarIconView: View {
    var body: some View {
        Image(nsImage: MenuBarIconImageProvider.menuBarImage)
            .renderingMode(.template)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .accessibilityHidden(true)
    }
}
