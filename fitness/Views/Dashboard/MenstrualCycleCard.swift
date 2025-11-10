import SwiftUI

struct MenstrualCycleCard: View {
    let gender: Gender
    private let visualHeight: CGFloat = 60 // match Steps/Distance chart height

    @AppStorage("menstrual_last_start_ts") private var lastStartTimestamp: Double = 0
    @AppStorage("menstrual_cycle_length_days") private var cycleLength: Int = 28
    @State private var showLogSheet = false

    private var lastStartDate: Date? {
        lastStartTimestamp > 0 ? Date(timeIntervalSince1970: lastStartTimestamp) : nil
    }

    private var nextPeriodDate: Date? {
        guard let last = lastStartDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: cycleLength, to: last)
    }
    private var hasRecord: Bool { lastStartDate != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerBar
            ringBlock
            bottomMeta
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .sheet(isPresented: $showLogSheet) {
            MenstrualLogSheet(lastStartTimestamp: $lastStartTimestamp, cycleLength: $cycleLength)
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
        }
    }

    private var headerBar: some View {
        HStack {
            // Left: icon + edit
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(Color.pink.opacity(0.12)).frame(width: 24, height: 24)
                    Image(systemName: "heart.fill").font(.caption).foregroundStyle(.pink)
                }
                Button {
                    showLogSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .padding(6)
                        .background(Color.primary.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
            }
            Spacer()
            // Right: days number + unit (no unit if no record)
            Group {
                if hasRecord {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(headerValueText)
                            .font(.title)
                            .foregroundStyle(Color.primary.opacity(0.8))
                        Text("天")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("--")
                        .font(.title)
                        .foregroundStyle(Color.primary.opacity(0.6))
                }
            }
        }
    }

    private var ringBlock: some View {
        Group {
            if lastStartDate != nil {
                cycleRing
            } else {
                emptyRing
            }
        }
    }

    private var bottomMeta: some View {
        HStack(spacing: 8) {
            if let next = nextPeriodDate {
                smallBadge(icon: "calendar", text: formatted(date: next))
            } else {
                smallBadge(icon: "calendar.badge.exclamationmark", text: "待记录")
            }
            Spacer()
        }
    }

    private var cycleRing: some View {
        let progress = cycleProgress ?? 0
        let remaining = max(daysUntilNext() ?? 0, 0)

        return ZStack {
            Circle().stroke(Color.pink.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.pink, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: visualHeight, height: visualHeight)
        .frame(maxWidth: .infinity)
    }

    private var emptyRing: some View {
        ZStack {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .foregroundStyle(Color.secondary.opacity(0.4))
                .frame(width: 120, height: 120)
            Button {
                showLogSheet = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
    private func daysUntilNext() -> Int? {
        guard let next = nextPeriodDate else { return nil }
        let diff = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: next)).day ?? 0
        return diff
    }

    @ViewBuilder
    private func pill(text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.pink.opacity(0.15), in: Capsule())
            .foregroundStyle(.pink)
    }

    private func badge(icon: String, text: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: icon)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color.pink.opacity(0.12), in: Capsule())
        .foregroundStyle(.pink)
    }

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

    private func metricRow(icon: String, title: String, value: String) -> some View { EmptyView() }

    private func infoBanner(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(10)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var daysSinceLastStart: Int? {
        guard let last = lastStartDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: last), to: Calendar.current.startOfDay(for: Date())).day
    }

    private var cycleProgress: Double? {
        guard let elapsed = daysSinceLastStart, cycleLength > 0 else { return nil }
        let fraction = Double(elapsed) / Double(cycleLength)
        return min(max(fraction, 0), 1)
    }

    private var headerValueText: String {
        guard hasRecord else { return "--" }
        if let days = daysUntilNext() { return String(max(days, 0)) }
        return "0"
    }
}

private struct MenstrualLogSheet: View {
    @Binding var lastStartTimestamp: Double
    @Binding var cycleLength: Int
    @Environment(\.dismiss) private var dismiss

    @State private var tempDate: Date
    @State private var tempLength: Double

    init(lastStartTimestamp: Binding<Double>, cycleLength: Binding<Int>) {
        self._lastStartTimestamp = lastStartTimestamp
        self._cycleLength = cycleLength

        let storedDate = lastStartTimestamp.wrappedValue > 0
        ? Date(timeIntervalSince1970: lastStartTimestamp.wrappedValue)
        : Date()

        _tempDate = State(initialValue: storedDate)
        _tempLength = State(initialValue: Double(max(cycleLength.wrappedValue, 28)))
    }

    var body: some View {
        NavigationStack {
            Color.clear
                .ignoresSafeArea()
                .overlay(sheetContent)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        lastStartTimestamp = tempDate.timeIntervalSince1970
                        cycleLength = Int(tempLength)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.pink)
                    }
                }
            }
        }
    }

    private var sheetContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let preview = predictedText {
                    infoChip(text: preview)
                }
                startDateCard
                cycleLengthCard
            }
            .padding()
        }
    }

    private var startDateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("最近一次经期开始", systemImage: "calendar")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            DatePicker("", selection: $tempDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(.pink)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    private var cycleLengthCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("平均周期长度", systemImage: "clock.arrow.circlepath")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(tempLength)) 天")
                        .font(.title2.weight(.bold))
                    Text("20-40 天之间较常见")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Stepper("", value: $tempLength, in: 20...40, step: 1)
                    .tint(.pink)
                    .labelsHidden()
            }
            Slider(value: $tempLength, in: 20...40, step: 1)
                .tint(.pink)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    private var predictedText: String? {
        guard let next = Calendar.current.date(byAdding: .day, value: Int(tempLength), to: tempDate) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return "预计下一次大约在 \(formatter.string(from: next))"
    }

    private var previewDateString: String {
        guard let next = Calendar.current.date(byAdding: .day, value: Int(tempLength), to: tempDate) else { return "--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: next)
    }

    private func infoChip(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(.pink)
            Text(text)
                .font(.footnote)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}
