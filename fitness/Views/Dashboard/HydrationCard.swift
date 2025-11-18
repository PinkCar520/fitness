import SwiftUI

struct HydrationCard: View {
    let targetLiters: Double
    private let incrementML: Double = 250
    private let visualHeight: CGFloat = 60 // match Steps/Distance chart height
    private let actionButtonSize: CGFloat = 28

    @AppStorage("hydration_today_amount_ml") private var storedAmount: Double = 0
    @AppStorage("hydration_last_reset_ts") private var lastResetTimestamp: Double = 0
    @State private var lastDeltaML: Double = 0 // signed; positive add, negative subtract

    // No extra animation state in the original design

    private var targetMilliliters: Double { max(targetLiters, 0.5) * 1000 }
    private var progress: Double { min(storedAmount / targetMilliliters, 1) }
    private var formattedTarget: String {
        if targetLiters >= 1 {
            return String(format: "%.1f L", targetLiters)
        }
        return "\(Int(targetMilliliters)) ml"
    }

    private var formattedCurrent: String {
        // Center number prefers liters to keep typography clean
        return String(format: "%.1f L", storedAmount / 1000)
    }
    private var formattedCurrentML: String { "\(Int(storedAmount))" }
    private var formattedTargetML: String { "\(Int(targetMilliliters)) ml" }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerBar
            ringBlock
            bottomMeta
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onAppear(perform: resetIfNeeded)
        .animation(.easeInOut, value: storedAmount)
        .contextMenu {
            Button("+250 ml") { addWater(amount: 250) }
            Button("+500 ml") { addWater(amount: 500) }
            Button("-250 ml") { removeWater(amount: 250) }
            Divider()
            Button("撤销最近一次", role: .destructive) { undoLast() }
            Button("重置今日", role: .destructive) { resetToday() }
        }
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(Color.blue.opacity(0.12)).frame(width: 24, height: 24)
                Image(systemName: "drop.fill").font(.caption).foregroundStyle(.blue)
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(storedAmount))")
                    .font(.title)
                    .contentTransition(.numericText(countsDown: false))
                    .foregroundStyle(Color.primary.opacity(0.8))
                Text("ml")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var ringBlock: some View {
        HStack(spacing: 12) {
            Button(action: { removeWater(amount: incrementML) }) {
                ZStack {
                    Circle().fill(Color.primary.opacity(0.06))
                        .frame(width: actionButtonSize, height: actionButtonSize)
                    Image(systemName: "minus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            ZStack {
                Circle().stroke(Color.cyan.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: visualHeight, height: visualHeight)

            Button(action: addWater) {
                ZStack {
                    Circle().fill(Color.blue.opacity(0.12))
                        .frame(width: actionButtonSize, height: actionButtonSize)
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.blue)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var bottomMeta: some View {
        HStack(spacing: 8) {
            smallBadge(icon: "drop", text: "\(formattedCurrentML)/\(formattedTargetML)")
            Spacer()
        }
    }

    private func addWater() { addWater(amount: incrementML) }

    private func addWater(amount: Double) {
        resetIfNeeded()
        let wasBelowGoal = storedAmount < targetMilliliters
        storedAmount = min(targetMilliliters * 1.5, storedAmount + amount)
        lastDeltaML = amount
        lastResetTimestamp = Date().timeIntervalSince1970
        Haptics.simpleTap()
        if wasBelowGoal && storedAmount >= targetMilliliters { Haptics.simpleSuccess() }
    }

    private func undoLast() {
        guard lastDeltaML != 0 else { return }
        storedAmount = max(0, storedAmount - lastDeltaML)
        lastDeltaML = 0
        Haptics.simpleTap()
    }

    private func removeWater(amount: Double) {
        resetIfNeeded()
        storedAmount = max(0, storedAmount - amount)
        lastDeltaML = -amount
        lastResetTimestamp = Date().timeIntervalSince1970
        Haptics.simpleTap()
    }

    private func resetIfNeeded() {
        let lastDate = Date(timeIntervalSince1970: lastResetTimestamp)
        if lastResetTimestamp == 0 || !Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
            resetToday()
        }
    }

    private func resetToday() {
        storedAmount = 0
        lastResetTimestamp = Date().timeIntervalSince1970
    }

    // No wave animation in the original

    private func smallBadge(icon: String, text: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: icon)
        }
        .font(.caption2)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.06), in: Capsule())
        .foregroundStyle(.secondary)
    }

    private func smallPill(text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.06), in: Capsule())
            .foregroundStyle(.secondary)
    }
}
