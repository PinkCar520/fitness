import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date?
    let completedDates: Set<Date>
    
    @State private var currentWeekStartDate: Date = Date()

    private let calendar = Calendar.current
    private var workingCalendar: Calendar {
        var cal = calendar
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        return cal
    }
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    // Brand Colors
    private let emeraldGreen = Color(red: 16/255, green: 185/255, blue: 129/255) // #10B981
    private let systemBlue = Color(red: 59/255, green: 130/255, blue: 246/255) // #3B82F6

    var body: some View {
        VStack(spacing: 18) {
            headerSection

            HStack(spacing: 0) {
                ForEach(Array(weekdayLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .textCase(.uppercase)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(weekDates, id: \.self) { date in
                    let isCompleted = completedDates.contains { calendar.isDate($0, inSameDayAs: date) }

                    DayView(
                        date: date,
                        selectedDate: $selectedDate,
                        emeraldGreen: emeraldGreen,
                        systemBlue: systemBlue,
                        isWeekend: calendar.isDateInWeekend(date),
                        isCompleted: isCompleted
                    )
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width < -50 {
                        changeWeek(by: 1)
                    } else if gesture.translation.width > 50 {
                        changeWeek(by: -1)
                    }
                }
        )
        .onAppear {
            syncWeekStart(with: selectedDate)
        }
        .onChange(of: selectedDate) { _, newValue in
            syncWeekStart(with: newValue)
        }
    }

    private var headerSection: some View {
        let displayDate = selectedDate ?? Date()

        return HStack(spacing: 12) {
            Text(dateFormatter.string(from: displayDate))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.92))
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(1)

            Spacer(minLength: 8)

            HStack(spacing: 10) {
                navButton(systemName: "chevron.left") {
                    changeWeek(by: -1)
                }

                todayButton

                navButton(systemName: "chevron.right") {
                    changeWeek(by: 1)
                }
            }
            .layoutPriority(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func todayButtonTapped() {
        let today = workingCalendar.startOfDay(for: Date())
        selectedDate = today
        syncWeekStart(with: today)
    }

    private var todayButton: some View {
        Button(action: todayButtonTapped) {
            Text("今天")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [systemBlue, Color(red: 65/255, green: 92/255, blue: 255/255)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .shadow(color: systemBlue.opacity(0.25), radius: 6, x: 0, y: 4)
    }

    private func navButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(systemBlue)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(systemBlue.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }

    private var weekdayLabels: [String] {
        workingCalendar.shortWeekdaySymbols
    }

    private var weekDates: [Date] {
        daysInWeek()
    }

    private func syncWeekStart(with date: Date?) {
        let target = date ?? Date()
        if let interval = workingCalendar.dateInterval(of: .weekOfYear, for: target) {
            currentWeekStartDate = workingCalendar.startOfDay(for: interval.start)
        }
    }

    private func changeWeek(by amount: Int) {
        if let newWeek = workingCalendar.date(byAdding: .day, value: amount * 7, to: currentWeekStartDate) {
            currentWeekStartDate = workingCalendar.startOfDay(for: newWeek)
            // Also update selectedDate to be within the new week if it's outside
            if let currentSelectedDate = selectedDate,
               !workingCalendar.isDate(currentSelectedDate, equalTo: currentWeekStartDate, toGranularity: .weekOfYear) {
                selectedDate = workingCalendar.startOfDay(for: newWeek) // Select the first day of the new week
            }
        }
    }

    private func daysInWeek() -> [Date] {
        guard let interval = workingCalendar.dateInterval(of: .weekOfYear, for: currentWeekStartDate) else {
            return []
        }

        var days: [Date] = []
        for offset in 0..<7 {
            if let day = workingCalendar.date(byAdding: .day, value: offset, to: interval.start) {
                days.append(workingCalendar.startOfDay(for: day))
            }
        }
        return days
    }
}

enum WorkoutTimeOfDay: String, CaseIterable {
    case morning
    case evening
    case none
}

enum WorkoutIntensity: String, CaseIterable {
    case high
    case medium
    case low
    case none
}

struct WorkoutDetail: Identifiable, Hashable {
    let id = UUID()
    let type: ActivityType
    let time: WorkoutTimeOfDay
    let intensity: WorkoutIntensity
}

enum ActivityType: String, CaseIterable {
    case workout
    case meal
    case meditation
    case water
    case sleep
    case steps
    case stand
    case exercise
    
    var color: Color {
        switch self {
        case .workout: return .red
        case .meal: return .green
        case .meditation: return .purple
        case .water: return .blue
        case .sleep: return .indigo
        case .steps: return .orange
        case .stand: return .yellow
        case .exercise: return .pink
        }
    }
    
    var icon: String {
        switch self {
        case .workout: return "figure.run"
        case .meal: return "fork.knife"
        case .meditation: return "leaf.fill"
        case .water: return "drop.fill"
        case .sleep: return "moon.fill"
        case .steps: return "figure.walk"
        case .stand: return "figure.stand"
        case .exercise: return "dumbbell.fill"
        }
    }
}

struct ProgressSegment: Identifiable {
    let id = UUID()
    let progress: Double // 0.0 to 1.0
    let color: Color
}

struct SegmentedProgressRingView: View {
    let segments: [ProgressSegment]
    let lineWidth: CGFloat

    init(segments: [ProgressSegment], lineWidth: CGFloat = 3) {
        self.segments = segments
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)

            // Segments
            ForEach(segments) { segment in
                let start = segments.prefix(while: { $0.id != segment.id }).reduce(0) { $0 + $1.progress }
                let end = start + segment.progress
                
                Circle()
                    .trim(from: CGFloat(start), to: CGFloat(min(end, 1.0)))
                    .stroke(segment.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(Angle(degrees: -90))
            }
        }
    }
}

struct TooltipView: View {
    let segments: [ProgressSegment]
    private let triangleHeight: CGFloat = 8
    private let triangleWidth: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("每日进度")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.bottom, 2)

            ForEach(segments) { segment in
                HStack {
                    Circle().fill(segment.color).frame(width: 8, height: 8)
                    Text(activityName(for: segment.color))
                    Spacer()
                    Text(String(format: "%.0f%%", segment.progress * 100))
                }
                .font(.caption)
            }
        }
        .padding(10)
        .frame(width: 110)
        .padding(.bottom, triangleHeight) // Add padding to make space for the triangle
        .background(
            TooltipBubble(cornerRadius: 10, triangleHeight: triangleHeight, triangleWidth: triangleWidth)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }

    private func activityName(for color: Color) -> String {
        switch color {
        case .green: return "饮食"
        case .red: return "锻炼"
        case .indigo: return "睡眠"
        case .purple: return "心理"
        default: return "活动"
        }
    }
}

struct TooltipBubble: Shape {
    let cornerRadius: CGFloat
    let triangleHeight: CGFloat
    let triangleWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let bodyRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height - triangleHeight)

        var path = Path()
        // Start at top-left after corner
        path.move(to: CGPoint(x: bodyRect.minX + cornerRadius, y: bodyRect.minY))
        // Top edge
        path.addLine(to: CGPoint(x: bodyRect.maxX - cornerRadius, y: bodyRect.minY))
        // Top-right corner
        path.addArc(center: CGPoint(x: bodyRect.maxX - cornerRadius, y: bodyRect.minY + cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        // Right edge
        path.addLine(to: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY - cornerRadius))
        // Bottom-right corner
        path.addArc(center: CGPoint(x: bodyRect.maxX - cornerRadius, y: bodyRect.maxY - cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        
        // Bottom edge until triangle
        path.addLine(to: CGPoint(x: rect.midX + triangleWidth / 2, y: bodyRect.maxY))
        // Triangle
        path.addLine(to: CGPoint(x: rect.midX, y: rect.height)) // The point
        path.addLine(to: CGPoint(x: rect.midX - triangleWidth / 2, y: bodyRect.maxY))

        // Bottom edge after triangle
        path.addLine(to: CGPoint(x: bodyRect.minX + cornerRadius, y: bodyRect.maxY))
        // Bottom-left corner
        path.addArc(center: CGPoint(x: bodyRect.minX + cornerRadius, y: bodyRect.maxY - cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        // Left edge
        path.addLine(to: CGPoint(x: bodyRect.minX, y: bodyRect.minY + cornerRadius))
        // Top-left corner
        path.addArc(center: CGPoint(x: bodyRect.minX + cornerRadius, y: bodyRect.minY + cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        
        path.closeSubpath()
        return path
    }
}

struct DayView: View {
    let date: Date
    @Binding var selectedDate: Date?
    let emeraldGreen: Color
    let systemBlue: Color
    let isWeekend: Bool
    let isCompleted: Bool

    @State private var showTooltip = false // New state for tooltip visibility

    private let calendar = Calendar.current

    private var isSelected: Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selected)
    }

    var body: some View {
        card
            .frame(width: 58, height: 64)
            .contentShape(Rectangle())
            .onTapGesture {
                let normalized = calendar.startOfDay(for: date)
                selectedDate = normalized
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.35)
                    .onEnded { _ in
                        presentTooltip()
                    }
            )
            .overlay(tooltipOverlay)
            .onChange(of: isSelected) { _, newValue in
                handleSelectionChange(isSelected: newValue)
            }
    }

    private var card: some View {
        ZStack {
            ringLayer
                .frame(width: 40, height: 40)

            innerCircle
                .frame(width: 30, height: 30)

            Text(String(calendar.component(.day, from: date)))
                .font(.system(size: 18, weight: .semibold))
                .kerning(-0.3)
                .foregroundStyle(isSelected ? Color.white : Color.primary.opacity(0.95))
        }
        .overlay(completionBadge, alignment: .topTrailing)
    }

    private var segments: [ProgressSegment] {
        mockSegments(for: date)
    }

    private var categoryDescriptors: [(color: Color, intensity: Double)] {
        let baseline: [Color] = [.green, .red, .indigo, .purple]
        var descriptors: [(Color, Double)] = []

        for (index, color) in baseline.enumerated() {
            let progress = index < segments.count ? min(max(segments[index].progress, 0), 1) : 0
            descriptors.append((color, progress))
        }

        return descriptors
    }

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var innerCircle: some View {
        Group {
            if isSelected {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                systemBlue.opacity(0.65),
                                Color(red: 88/255, green: 110/255, blue: 255/255).opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
        }
    }

    private var ringLayer: some View {
        let totalSegments = max(categoryDescriptors.count, 1)
        let span = 1.0 / Double(totalSegments)
        let lineWidth: CGFloat = isSelected ? 6 : 5

        return ZStack {
            ForEach(Array(categoryDescriptors.enumerated()), id: \.offset) { index, descriptor in
                let start = Double(index) * span + 0.02
                let end = (Double(index) + 1) * span - 0.02
                let progressEnd = start + (end - start) * min(descriptor.intensity, 1)

                Circle()
                    .trim(from: start, to: end)
                    .stroke(
                        descriptor.color.opacity(isSelected ? 0.18 : 0.12),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                if descriptor.intensity > 0 {
                    Circle()
                        .trim(from: start, to: progressEnd)
                        .stroke(
                            progressColor(for: descriptor.color, intensity: descriptor.intensity),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.25), value: descriptor.intensity)
                }
            }
        }
    }

    private func progressColor(for baseColor: Color, intensity: Double) -> Color {
        let normalized = min(max(intensity, 0), 1)
        let baseOpacity = isSelected ? 0.82 : 0.65
        let bonus = 0.18 * normalized
        return baseColor.opacity(baseOpacity + bonus)
    }

    private var completionBadge: some View {
        EmptyView()
    }

    private var tooltipOverlay: some View {
        Group {
            if showTooltip {
                TooltipView(segments: segments)
                    .offset(y: -92)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: showTooltip)
    }

    private func handleSelectionChange(isSelected: Bool) {
        if !isSelected {
            showTooltip = false
        }
    }

    private func presentTooltip() {
        showTooltip = true
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            showTooltip = false
        }
    }

    private func mockSegments(for date: Date) -> [ProgressSegment] {
        let day = Double(calendar.component(.day, from: date))
        
        // Create progress that cycles through the month, reflecting new proportions
        let mealProgress = (day.truncatingRemainder(dividingBy: 5)) / 16.66 // Max ~0.3 (30%)
        let workoutProgress = (day.truncatingRemainder(dividingBy: 7)) / 23.33 // Max ~0.3 (30%)
        let sleepProgress = (day.truncatingRemainder(dividingBy: 6)) / 30.0  // Max ~0.2 (20%)
        let meditationProgress = (day.truncatingRemainder(dividingBy: 4)) / 20.0 // Max ~0.2 (20%)

        return [
            ProgressSegment(progress: mealProgress, color: .green),
            ProgressSegment(progress: workoutProgress, color: .red),
            ProgressSegment(progress: sleepProgress, color: .indigo),
            ProgressSegment(progress: meditationProgress, color: .purple)
        ]
    }
}

extension Calendar {
    func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        return isDate(date1, equalTo: date2, toGranularity: .day)
    }
}

struct CalendarView_Previews: PreviewProvider {
    @State static var selectedDate: Date? = Date()
    static var previews: some View {
        // Create a sample set of completed dates for preview
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let completedDates: Set<Date> = [yesterday, twoDaysAgo]

        CalendarView(selectedDate: $selectedDate, completedDates: completedDates)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
