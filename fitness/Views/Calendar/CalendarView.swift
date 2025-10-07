import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentWeekStartDate: Date = Date()

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN") // Ensure Chinese locale for EEEE
        return formatter
    }()

    // Brand Colors
    private let emeraldGreen = Color(red: 16/255, green: 185/255, blue: 129/255) // #10B981
    private let energyOrange = Color(red: 249/255, green: 115/255, blue: 22/255) // #F97316
    private let systemBlue = Color(red: 59/255, green: 130/255, blue: 246/255) // #3B82F6

    var body: some View {
        VStack(spacing: 0) { // Set spacing to 0 for tighter control
            // Top Full Date and Today Button
            HStack {
                Text(fullDateFormatter.string(from: selectedDate))
                    .font(.system(size: 24, weight: .bold)) // Larger, bolder font
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2)) // Dark gray #333
                    .kerning(-0.5) // Tight letter spacing
                Spacer()
                Button(action: { 
                    selectedDate = Date()
                    currentWeekStartDate = Date()
                }) {
                    Text("今天")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(systemBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(systemBlue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 15)
            .padding(.bottom, 10)

            // Weekday headers
            HStack {
                ForEach(0..<7) { index in
                    Text(reorderedWeekdaySymbol(for: index))
                        .font(.system(size: 13, weight: .light)) // Smaller, lighter font
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6)) // Light gray #999
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 5)

                // Days grid (now only one week)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(daysInWeek(), id: \.self) { date in
                        // Mock workout details for demonstration
                        let mockWorkoutDetails: [WorkoutDetail] = {
                            var details: [WorkoutDetail] = []
                            if calendar.isDate(date, inSameDayAs: Date()) {
                                details.append(WorkoutDetail(type: .workout, time: .morning, intensity: .high))
                                details.append(WorkoutDetail(type: .meal, time: .none, intensity: .none))
                            } else if calendar.component(.day, from: date) % 3 == 0 {
                                details.append(WorkoutDetail(type: .sleep, time: .none, intensity: .none))
                                details.append(WorkoutDetail(type: .workout, time: .evening, intensity: .low))
                            } else if calendar.component(.day, from: date) % 5 == 0 {
                                details.append(WorkoutDetail(type: .water, time: .none, intensity: .none))
                                details.append(WorkoutDetail(type: .steps, time: .none, intensity: .none))
                                details.append(WorkoutDetail(type: .workout, time: .morning, intensity: .medium))
                            } else if calendar.component(.day, from: date) % 7 == 0 {
                                details.append(WorkoutDetail(type: .workout, time: .evening, intensity: .high))
                            }
                            return details
                        }()

                        DayView(date: date, selectedDate: $selectedDate, emeraldGreen: emeraldGreen, energyOrange: energyOrange, systemBlue: systemBlue, isWeekend: calendar.isDateInWeekend(date), workoutDetails: mockWorkoutDetails, isRecordBreaking: calendar.component(.day, from: date) == 15 ? true : false, isConsecutiveWorkout: calendar.component(.day, from: date) == 16 ? true : false)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 15)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white) // White card background
        .cornerRadius(20) // rounded-2xl
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1) // border border-gray-100/50
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2) // shadow-sm
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width < -50 { // Swipe left
                        changeWeek(by: 1)
                    } else if gesture.translation.width > 50 { // Swipe right
                        changeWeek(by: -1)
                    }
                }
        )
    }

    private func weekdaySymbol(for index: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols[index]
    }

    private func reorderedWeekdaySymbol(for index: Int) -> String {
        let symbols = calendar.shortWeekdaySymbols
        let mondayIndex = (calendar.firstWeekday == 1) ? 1 : 0 // If firstWeekday is Sunday (1), Monday is at index 1. Otherwise, it's at index 0.
        let reorderedSymbols = Array(symbols[mondayIndex..<symbols.count] + symbols[0..<mondayIndex])
        return reorderedSymbols[index]
    }

    private func changeWeek(by amount: Int) {
        if let newWeek = calendar.date(byAdding: .day, value: amount * 7, to: currentWeekStartDate) {
            currentWeekStartDate = newWeek
            // Also update selectedDate to be within the new week if it's outside
            if !calendar.isDate(selectedDate, equalTo: currentWeekStartDate, toGranularity: .weekOfYear) {
                selectedDate = newWeek // Select the first day of the new week
            }
        }
    }

    private func daysInWeek() -> [Date] {
        var days: [Date] = []
        let weekdayOfCurrentWeekStartDate = calendar.component(.weekday, from: currentWeekStartDate)
        let adjustedFirstWeekday = 2 // Monday
        let offset = (weekdayOfCurrentWeekStartDate - adjustedFirstWeekday + 7) % 7

        guard let firstDayOfGrid = calendar.date(
            byAdding: .day,
            value: -offset,
            to: currentWeekStartDate
        ) else {
            return []
        }

        for i in 0..<7 { // Only 7 days for a week view
            if let dayDate = calendar.date(byAdding: .day, value: i, to: firstDayOfGrid) {
                days.append(dayDate)
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
    let lineWidth: CGFloat = 3

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
        .frame(width: 20, height: 20)
    }
}

struct TooltipView: View {
    let segments: [ProgressSegment]

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
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(width: 120)
    }

    private func activityName(for color: Color) -> String {
        switch color {
        case .green: return "餐饮"
        case .blue: return "喝水"
        case .indigo: return "睡眠"
        default: return "活动"
        }
    }
}

struct DayView: View {
    let date: Date
    @Binding var selectedDate: Date
    let emeraldGreen: Color
    let energyOrange: Color
    let systemBlue: Color
    let isWeekend: Bool
    var workoutDetails: [WorkoutDetail] = []
    let isRecordBreaking: Bool
    let isConsecutiveWorkout: Bool // New parameter
    
    @State private var showTooltip = false

    private let calendar = Calendar.current

    var body: some View {
        let segments = mockSegments(for: date)

        VStack(spacing: 4) {
            Text(String(calendar.component(.day, from: date)))
                .font(.system(size: 17, weight: .bold))
                .kerning(-0.2)
                .foregroundColor(isSelected ? .white : (isWeekend ? Color.gray.opacity(0.6) : Color(red: 0.2, green: 0.2, blue: 0.2)))
                .frame(width: 48, height: 48)
                .background(
                    ZStack {
                        if isSelected {
                            LinearGradient(
                                gradient: Gradient(colors: [systemBlue, Color(red: 100/255, green: 100/255, blue: 255/255)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.clear
                        }
                    }
                )
                .clipShape(Circle())
                .shadow(color: isSelected ? systemBlue.opacity(0.3) : .clear, radius: isSelected ? 5 : 0, x: 0, y: isSelected ? 3 : 0)

            // Status Icons
            HStack(spacing: 4) {
                if workoutDetails.contains(where: { $0.intensity == .high }) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }

                if isRecordBreaking {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                }

                if isConsecutiveWorkout {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }
            }
            .frame(height: 10)

            // Main Activity Type Icon & Ring
            if workoutDetails.contains(where: { $0.type == .workout }) {
                Image(systemName: ActivityType.workout.icon)
                    .font(.system(size: 12))
                    .foregroundColor(isFutureDate ? ActivityType.workout.color.opacity(0.4) : ActivityType.workout.color)
            } else {
                // Placeholder to keep spacing consistent for non-workout days
                Spacer().frame(height: 12)
            }
            
            SegmentedProgressRingView(segments: segments)
        }
        .contentShape(Rectangle()) // Make the whole area tappable
        .onTapGesture {
            selectedDate = date
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            showTooltip = true
        }
        .overlay(
            ZStack {
                if showTooltip {
                    // Dismiss on tap outside
                    Color.black.opacity(0.001)
                        .onTapGesture {
                            showTooltip = false
                        }

                    TooltipView(segments: segments)
                        .offset(y: -95)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showTooltip)
        )
    }

    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private var isFutureDate: Bool {
        calendar.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
    }

    private func mockSegments(for date: Date) -> [ProgressSegment] {
        let day = Double(calendar.component(.day, from: date))
        
        // Create progress that cycles through the month to demonstrate 0-100% capability
        let mealProgress = (day.truncatingRemainder(dividingBy: 5)) / 8.0 // Max 0.5
        let waterProgress = (day.truncatingRemainder(dividingBy: 4)) / 8.0 // Max 0.375
        let sleepProgress = (day.truncatingRemainder(dividingBy: 6)) / 10.0 // Max 0.5
        
        return [
            ProgressSegment(progress: mealProgress, color: .green),
            ProgressSegment(progress: waterProgress, color: .blue),
            ProgressSegment(progress: sleepProgress, color: .indigo)
        ]
    }
}

extension Calendar {
    func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        return isDate(date1, equalTo: date2, toGranularity: .day)
    }
}

struct CalendarView_Previews: PreviewProvider {
    @State static var selectedDate = Date()
    static var previews: some View {
        let calendar = Calendar.current // Local calendar instance
        CalendarView(selectedDate: $selectedDate)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
