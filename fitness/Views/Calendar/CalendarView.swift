
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
                    // Mock activity types for demonstration
                    let mockActivityTypes: [ActivityType] = {
                        if calendar.isDate(date, inSameDayAs: Date()) {
                            return [.workout, .meal]
                        } else if calendar.component(.day, from: date) % 3 == 0 {
                            return [.sleep]
                        } else if calendar.component(.day, from: date) % 5 == 0 {
                            return [.water, .steps]
                        } else {
                            return []
                        }
                    }()

                    DayView(date: date, selectedDate: $selectedDate, emeraldGreen: emeraldGreen, energyOrange: energyOrange, systemBlue: systemBlue, isWeekend: calendar.isDateInWeekend(date), activityTypes: mockActivityTypes)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 15)
        }
        .background(
            ZStack {
                Color.white.opacity(0.9) // bg-white/90
                // For backdrop-blur-xl, we typically rely on the system's material effects
                // or use a custom blur effect. For now, a translucent white is a good start.
            }
        )
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

struct DayView: View {
    let date: Date
    @Binding var selectedDate: Date
    let emeraldGreen: Color
    let energyOrange: Color
    let systemBlue: Color
    let isWeekend: Bool
    var activityTypes: [ActivityType] = [] // Changed to array of ActivityType
    @GestureState private var isDetectingLongPress = false // For scale effect

    private let calendar = Calendar.current // Added local calendar instance

    var body: some View {
        VStack(spacing: 4) {
            Text(String(calendar.component(.day, from: date)))
                .font(.system(size: 17, weight: .bold)) // Larger font size, bold weight
                .kerning(-0.2) // Tight letter spacing
                .foregroundColor(isSelected ? .white : (isWeekend ? Color.gray.opacity(0.6) : Color(red: 0.2, green: 0.2, blue: 0.2))) // White if selected, lighter gray for weekend, dark gray otherwise
                .frame(width: 48, height: 48) // Increased size for better tap area
                .background(
                    ZStack {
                        if isSelected {
                            LinearGradient(
                                gradient: Gradient(colors: [systemBlue, Color(red: 100/255, green: 100/255, blue: 255/255)]), // Example gradient from blue to a lighter blue/purple
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.clear
                        }
                    }
                )
                .clipShape(Circle()) // Circular background
                .shadow(color: isSelected ? systemBlue.opacity(0.3) : .clear, radius: isSelected ? 5 : 0, x: 0, y: isSelected ? 3 : 0) // Shadow for selected date
                .scaleEffect(isDetectingLongPress ? 0.95 : 1.0) // Scale effect on tap

            // Activity Status Indicators (multiple dots)
            HStack(spacing: 2) {
                ForEach(activityTypes, id: \.self) { type in
                    Circle().fill(type.color).frame(width: 5, height: 5)
                }
            }
        }
        .animation(.spring(), value: isDetectingLongPress) // Animation for scale effect
        .gesture(
            LongPressGesture(minimumDuration: 0.01) // Use LongPressGesture for immediate feedback
                .updating($isDetectingLongPress) { currentState, gestureState, transaction in
                    gestureState = currentState
                }
                .onEnded { _ in // Add onEnded to update selectedDate
                    selectedDate = date
                }
        )
    }

    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
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
