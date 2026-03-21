import SwiftUI

struct ReminderOverlayView: View {
    let event: ReminderEvent

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )

            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(iconBackground)
                    icon
                }
                .frame(width: 76, height: 76)

                VStack(alignment: .leading, spacing: 8) {
                    Text(sideLabel)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(accentColor.opacity(0.12))
                        )
                    Text(event.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(event.subtitle)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 26)
        }
        .frame(width: 420)
    }

    private var icon: some View {
        Group {
            switch event.kind {
            case .low:
                Image(systemName: "bolt.badge.clock.fill")
            case .charged:
                Image(systemName: "checkmark.circle.fill")
            }
        }
        .font(.system(size: 28, weight: .semibold))
        .foregroundStyle(.white)
    }

    private var iconBackground: LinearGradient {
        switch normalizedSides {
        case [.left]:
            return LinearGradient(colors: [Color.blue.opacity(0.9), Color.cyan.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case [.right]:
            return LinearGradient(colors: [Color.red.opacity(0.88), Color.pink.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Color.gray.opacity(0.82), Color.black.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var normalizedSides: [BudSide] {
        event.sides.sorted()
    }

    private var sideLabel: String {
        switch normalizedSides {
        case [.left]:
            return "LEFT"
        case [.right]:
            return "RIGHT"
        default:
            return "BOTH"
        }
    }

    private var accentColor: Color {
        switch normalizedSides {
        case [.left]:
            return .blue
        case [.right]:
            return .red
        default:
            return .gray
        }
    }
}
