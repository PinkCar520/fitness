import SwiftUI

/// A reusable card container that applies unified padding, background, and corner radius.
struct DashboardSurface<Content: View>: View {
    private let cornerRadius: CGFloat
    private let shadowOpacity: Double
    private let content: Content
    private let background: AnyShapeStyle

    init(
        cornerRadius: CGFloat = 24,
        shadowOpacity: Double = 0.08,
        background: some ShapeStyle = Color(UIColor.secondarySystemGroupedBackground),
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.shadowOpacity = shadowOpacity
        self.background = AnyShapeStyle(background)
        self.content = content()
    }

    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(background)
                    .shadow(color: Color.black.opacity(shadowOpacity), radius: 16, x: 0, y: 8)
            )
    }
}

/// Lightweight chip model for QuickAction metadata
struct QuickActionChip: Equatable, Hashable {
    let icon: String?
    let text: String
}

/// Capsule-style chip used for inline metadata (e.g., status, type badges).
struct InfoChip: View {
    let icon: String?
    let text: String
    var tint: Color = .white.opacity(0.9)
    var backgroundColor: Color = Color.white.opacity(0.16)

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .foregroundColor(tint)
        .background(backgroundColor, in: Capsule())
    }
}

/// Prominent button for quick, primary actions such as "Start Workout" or "Log Weight".
struct QuickActionButton: View {
    let title: String
    let subtitle: String?
    let icon: String
    var tint: Color = .accentColor
    var chips: [QuickActionChip]? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.15), in: Circle())
                    .foregroundColor(tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let chips, !chips.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(chips, id: \.self) { chip in
                                InfoChip(icon: chip.icon, text: chip.text, tint: .secondary, backgroundColor: Color.primary.opacity(0.06))
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

/// Data-driven card to surface insights, reminders, or guidance to the user.
/// Note: InsightCard is deprecated on Dashboard; still used in Plan view.
struct InsightCard: View {
    struct Action {
        let title: String
        let icon: String
        let handler: () -> Void
    }

    let title: String
    let description: String
    var tone: Tone = .informational
    var action: Action?

    enum Tone {
        case informational
        case positive
        case warning

        var gradient: LinearGradient {
            switch self {
            case .informational:
                return LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.9),
                        Color.accentColor.opacity(0.55)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .positive:
                return LinearGradient(
                    colors: [
                        Color.green.opacity(0.9),
                        Color.green.opacity(0.55)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .warning:
                return LinearGradient(
                    colors: [
                        Color.orange.opacity(0.9),
                        Color.orange.opacity(0.55)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }

        var icon: String {
            switch self {
            case .informational:
                return "sparkles"
            case .positive:
                return "trophy.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            }
        }
    }

    var body: some View {
        DashboardSurface(background: tone.gradient) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: tone.icon)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                }

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))

                if let action {
                    Button(action: action.handler) {
                        HStack(spacing: 8) {
                            Image(systemName: action.icon)
                                .font(.caption.weight(.bold))
                            Text(action.title)
                                .font(.caption.weight(.bold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                        .background(Color.white.opacity(0.2), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
