import SwiftUI

struct MonthView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth: Date = Date()

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    // Brand Colors (duplicated from CalendarView for now)
    private let emeraldGreen = Color(red: 16/255, green: 185/255, blue: 129/255) // #10B981
    private let energyOrange = Color(red: 249/255, green: 115/255, blue: 22/255) // #F97316
    private let systemBlue = Color(red: 59/255, green: 130/255, blue: 246/255) // #3B82F6

    var body: some View {
        VStack {
            // Month navigation
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(dateFormatter.string(from: currentMonth))
                    .font(.headline)
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            // Weekday headers
            HStack {
                ForEach(0..<7) { index in
                    Text(reorderedWeekdaySymbol(for: index))
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(daysInMonth(), id: \.self) { date in
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
                        .onTapGesture {
                            selectedDate = date
                        }
                }
            }
            .padding(.horizontal)
        }
    }

    private func reorderedWeekdaySymbol(for index: Int) -> String {
        let symbols = calendar.shortWeekdaySymbols
        let mondayIndex = (calendar.firstWeekday == 1) ? 1 : 0 // If firstWeekday is Sunday (1), Monday is at index 1. Otherwise, it's at index 0.
        let reorderedSymbols = Array(symbols[mondayIndex..<symbols.count] + symbols[0..<mondayIndex])
        return reorderedSymbols[index]
    }

    private func changeMonth(by amount: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: amount, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func daysInMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        let firstDayOfMonth = monthInterval.start

        let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth)
        let adjustedFirstWeekday = 2 // Monday
        let offset = (weekdayOfFirstDay - adjustedFirstWeekday + 7) % 7

        guard let firstDayOfGrid = calendar.date(
            byAdding: .day,
            value: -offset,
            to: firstDayOfMonth
        ) else {
            return []
        }

        var days: [Date] = []
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: firstDayOfGrid)

        for _ in 0..<42 {
            guard let date = calendar.date(from: dateComponents) else {
                fatalError("Could not create date from components") // Should not happen
            }
            days.append(date)
            dateComponents.day! += 1 // Increment day
        }
        return days
    }
}

struct MonthView_Previews: PreviewProvider {
    @State static var selectedDate = Date()
    static var previews: some View {
        MonthView(selectedDate: $selectedDate)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}