import SwiftUI

// MARK: - Supporting Enums and Structs

enum TrainingDifficulty: String, CaseIterable, Identifiable {
    case beginner = "初级"
    case intermediate = "中级"
    case advanced = "高级"
    var id: String { self.rawValue }
}

enum Weekday: String, CaseIterable, Identifiable {
    case monday = "周一"
    case tuesday = "周二"
    case wednesday = "周三"
    case thursday = "周四"
    case friday = "周五"
    case saturday = "周六"
    case sunday = "周日"
    var id: String { self.rawValue }
}

struct PlanConfiguration {
    var goal: FitnessGoal = .fatLoss
    var targetWeight: Double = 65.0
    var workoutDurationPerSession: Int = 45
    var workoutFrequency: Int = 3
    var trainingDays: Set<Weekday> = []
    var sleepDurationTarget: Int = 8
    var planDuration: Int = 30
}

// MARK: - Main View

struct PlanSetupView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var config = PlanConfiguration()
    @State private var currentStep = 0
    
    var onComplete: (PlanConfiguration) -> Void

    private let totalSteps = 7

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $currentStep) {
                    GoalStepView(selectedGoal: $config.goal, currentStep: $currentStep).tag(0)
                    TargetWeightStepView(targetWeight: $config.targetWeight, currentStep: $currentStep).tag(1)
                    DurationStepView(duration: $config.workoutDurationPerSession, currentStep: $currentStep).tag(2)
                    LifestyleStepView(sleepTarget: $config.sleepDurationTarget).tag(3)
                    CycleStepView(planDuration: $config.planDuration).tag(4)
                    ScheduleStepView(frequency: $config.workoutFrequency, selectedDays: $config.trainingDays).tag(5)
                    ConfirmationStepView(config: config, onComplete: {
                        onComplete(config)
                        dismiss()
                    }).tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("制定新计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
    }
}

// MARK: - Animated Icon

private struct AnimatedRunningIcon: View {
    @State private var isAnimating = false

    var body: some View {
        Image(systemName: "figure.run")
            .font(.system(size: 48))
            .foregroundColor(.accentColor)
            .opacity(isAnimating ? 0.7 : 1.0)
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Step Subviews

private struct GoalStepView: View {
    @Binding var selectedGoal: FitnessGoal
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            AnimatedRunningIcon()
            Spacer().frame(height: 30)
            Text("您的主要目标是什么？").font(.largeTitle).bold().multilineTextAlignment(.center)
            ForEach(FitnessGoal.allCases) { goal in
                OptionCard(title: goal.rawValue, isSelected: goal == selectedGoal) {
                    selectedGoal = goal
                    withAnimation { currentStep += 1 }
                }
            }
        }.padding()
    }
}

private struct TargetWeightStepView: View {
    @Binding var targetWeight: Double
    @Binding var currentStep: Int

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            AnimatedRunningIcon()
            Spacer().frame(height: 30)
            Text("您的目标体重是？").font(.largeTitle).bold().multilineTextAlignment(.center)
            
            TargetWeightSlider(weight: $targetWeight, initialWeight: targetWeight)
                .frame(height: 120)
            
            Spacer()
            
            Button("下一步") {
                withAnimation { currentStep += 1 }
            }
            .font(.headline)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)

        }.padding()
    }
}

private struct DurationStepView: View {
    @Binding var duration: Int
    @Binding var currentStep: Int
    let durations = [30, 45, 60, 75, 90]

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            AnimatedRunningIcon()
            Spacer().frame(height: 30)
            Text("每次运动多长时间？").font(.largeTitle).bold().multilineTextAlignment(.center)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                ForEach(durations, id: \.self) { d in
                    OptionCard(title: "\(d)分钟", isSelected: d == duration, isCompact: true) {
                        duration = d
                        withAnimation { currentStep += 1 }
                    }
                }
            }
        }.padding()
    }
}

private struct ScheduleStepView: View {
    @Binding var frequency: Int
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            AnimatedRunningIcon()
            Spacer().frame(height: 30)
            Text("请选择您的训练日").font(.largeTitle).bold().multilineTextAlignment(.center)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(Weekday.allCases) { day in
                    OptionCard(title: day.rawValue, isSelected: selectedDays.contains(day), isCompact: true) {
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    }
                }
            }
            Spacer()
            Text("选择后可通过滑动进入下一步").font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .onChange(of: selectedDays) {
            frequency = selectedDays.count
        }
    }
}

private struct LifestyleStepView: View {
    @Binding var sleepTarget: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            AnimatedRunningIcon()
            Spacer().frame(height: 30)
            Text("您的生活方式目标？").font(.largeTitle).bold().multilineTextAlignment(.center)
            Text("目标睡眠时长 (小时)").font(.title2).bold()
            Picker("", selection: $sleepTarget, content: {
                ForEach(5...10, id: \.self) { hour in
                    Text("\(hour) 小时").tag(hour)
                }
            })
            .pickerStyle(.wheel)
            .frame(height: 150)
            Spacer()
        }.padding()
    }
}

private struct CycleStepView: View {
    @Binding var planDuration: Int

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            AnimatedRunningIcon()
            Spacer().frame(height: 30)
            Text("计划总周期？").font(.largeTitle).bold().multilineTextAlignment(.center)
            Text("选择整个计划的总时长 (天)").font(.title2).bold()
            Slider(value: .init(get: { Double(planDuration) }, set: { planDuration = Int($0) }), in: 7...90, step: 1)
                .padding(.horizontal)
            Text("\(planDuration) 天").font(.largeTitle).bold()
            Spacer()
        }.padding()
    }
}

private struct ConfirmationStepView: View {
    let config: PlanConfiguration
    let onComplete: () -> Void
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .center, spacing: 12) {
                    Spacer()
                    AnimatedRunningIcon().padding(.top, 10)
                    Text("确认您的计划").font(.largeTitle).bold().multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.bottom, 10)
                    
                    LazyVGrid(columns: columns, spacing: 12) {
                        ConfirmationCard(iconName: "flag.fill", label: "主要目标", value: config.goal.rawValue)
                        ConfirmationCard(iconName: "figure.scale", label: "目标体重", value: String(format: "%.0f kg", config.targetWeight))
                        ConfirmationCard(iconName: "calendar", label: "每周频率", value: "\(config.workoutFrequency) 天")
                        ConfirmationCard(iconName: "hourglass", label: "每次时长", value: "\(config.workoutDurationPerSession) 分钟")
                        ConfirmationCard(iconName: "bed.double.fill", label: "睡眠目标", value: "\(config.sleepDurationTarget) 小时")
                        ConfirmationCard(iconName: "calendar.badge.clock", label: "计划总长", value: "\(config.planDuration) 天")
                    }

                    ConfirmationCard(iconName: "checklist", label: "训练日", value: config.trainingDays.isEmpty ? "未指定" : config.trainingDays.map { $0.rawValue }.sorted().joined(separator: ", "))
                    
                    Button(action: onComplete) {
                        Text("生成计划")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(32)
                    }
                    .padding(.top, 15)
                }
                .padding()
                .frame(minHeight: geometry.size.height)
            }
        }
    }
}

// MARK: - Reusable Components

private struct TargetWeightSlider: View {
    @Binding var weight: Double
    let initialWeight: Double
    var rangeSpan: Double = 2.0

    // MARK: - Private Constants
    private let padding: CGFloat = 2
    private let thumbWidth: CGFloat = 50
    private let trackPadding: CGFloat = 5 // Safe margin inside the track

    // MARK: - Computed Properties
    private var allPossibleWeights: [Double] {
        let lowerBound = max(30.0, initialWeight - rangeSpan)
        let upperBound = min(200.0, initialWeight + rangeSpan)
        return Array(stride(from: lowerBound, through: upperBound, by: 0.1))
    }

    private var majorMarks: [Double] {
        var marks: [Double] = []
        let actualLowerBound = max(30.0, initialWeight - rangeSpan)
        let actualUpperBound = min(200.0, initialWeight + rangeSpan)

        let lowerInt = Int(ceil(actualLowerBound))
        let upperInt = Int(floor(actualUpperBound))

        for i in lowerInt...upperInt {
            marks.append(Double(i))
        }
        return marks.sorted()
    }

    private var halfMajorMarks: [Double] {
        return allPossibleWeights.filter { isHalfMajor($0) }
    }

    // MARK: - State
    private let feedbackGenerator = UISelectionFeedbackGenerator()

    // MARK: - Init
    init(weight: Binding<Double>, initialWeight: Double) {
        self._weight = weight
        self.initialWeight = initialWeight
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            let sliderWidth = geometry.size.width - 2 * padding
            
            ZStack {
                // The slider content view
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 60)

                    // Tick Marks
                    ForEach(0..<allPossibleWeights.count, id: \.self) { index in
                        let markValue = allPossibleWeights[index]
                        let isMajor = majorMarks.contains(markValue)
                        let isHalf = isHalfMajor(markValue)
                        let tickHeight: CGFloat = isMajor ? 16 : (isHalf ? 13 : 10)
                        Rectangle()
                            .fill(Color.gray.opacity(isMajor ? 0.8 : (isHalf ? 0.6 : 0.4)))
                            .frame(width: 1, height: tickHeight)
                            .offset(x: positionForValue(markValue, sliderWidth: sliderWidth) - 0.5)
                    }

                    // Major Mark Labels
                    ForEach(majorMarks, id: \.self) { markValue in
                        VStack(spacing: 2) {
                            Text(String(format: "%.0f", markValue))
                                .font(.caption)
                                .foregroundColor(getMarkColor(for: markValue))
                        }
                        .frame(width: thumbWidth)
                        .offset(x: positionForValue(markValue, sliderWidth: sliderWidth) - (thumbWidth / 2))
                        .offset(y: 15)
                    }
                    
                    // Initial Weight Marker (Not needed for target, but kept for copy)
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .offset(x: positionForValue(initialWeight, sliderWidth: sliderWidth) - 3)
                        .offset(y: -10)

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbWidth, height: thumbWidth)
                        .overlay(Text(getThumbText()).font(.headline).foregroundColor(.black))
                        .offset(x: getThumbXOffset(sliderWidth: sliderWidth))
                }
                .frame(width: sliderWidth)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let newThumbCenterX = gesture.location.x
                            let trackStart = (thumbWidth / 2) + trackPadding
                            let trackEnd = sliderWidth - (thumbWidth / 2) - trackPadding
                            let clampedX = max(trackStart, min(newThumbCenterX, trackEnd))
                            
                            let continuousValue = valueForPosition(clampedX, sliderWidth: sliderWidth)
                            let snappedValue = round(continuousValue * 10) / 10.0
                            
                            if self.weight != snappedValue {
                                self.weight = snappedValue
                                self.feedbackGenerator.selectionChanged()
                            }
                        }
                )
            }
            .frame(width: geometry.size.width)
            .onAppear {
                weight = initialWeight
                feedbackGenerator.prepare()
            }
        }
        .frame(height: 80)
    }

    // MARK: - Helper Functions

    private func getMarkColor(for mark: Double) -> Color {
        if mark == initialWeight {
            return .black
        } else if abs(weight - mark) < 0.5 {
            return .black.opacity(0.8)
        }
        return .gray
    }

    private func getThumbText() -> String {
        return String(format: "%.0f", weight)
    }

    private func positionForValue(_ value: Double, sliderWidth: CGFloat) -> CGFloat {
        let valueRange = (initialWeight + rangeSpan) - (initialWeight - rangeSpan)
        guard valueRange != 0 else { return sliderWidth / 2 }
        
        let ratio = (value - (initialWeight - rangeSpan)) / valueRange
        let trackWidth = sliderWidth - thumbWidth - (2 * trackPadding)
        let trackStart = (thumbWidth / 2) + trackPadding
        
        return trackStart + (ratio * trackWidth)
    }

    private func valueForPosition(_ x: CGFloat, sliderWidth: CGFloat) -> Double {
        let trackWidth = sliderWidth - thumbWidth - (2 * trackPadding)
        let trackStart = (thumbWidth / 2) + trackPadding
        let relativeX = x - trackStart
        let ratio = max(0, min(1, relativeX / trackWidth))
        
        let valueRange = (initialWeight + rangeSpan) - (initialWeight - rangeSpan)
        let value = (initialWeight - rangeSpan) + ratio * valueRange
        return value
    }

    private func getThumbXOffset(sliderWidth: CGFloat) -> CGFloat {
        let centerX = getThumbCenterX(sliderWidth: sliderWidth)
        return centerX - thumbWidth / 2
    }
    
    private func getThumbCenterX(sliderWidth: CGFloat) -> CGFloat {
        return positionForValue(weight, sliderWidth: sliderWidth)
    }

    private func isHalfMajor(_ value: Double) -> Bool {
        return value.truncatingRemainder(dividingBy: 1.0) == 0.5
    }
}

private struct ConfirmationCard: View {
    let iconName: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray5))
        .cornerRadius(12)
    }
}

private struct OptionCard: View {
    let title: String
    let isSelected: Bool
    var isCompact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(isCompact ? .body : .title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.accentColor : Color(UIColor.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

struct PlanSetupView_Previews: PreviewProvider {
    static var previews: some View {
        PlanSetupView { config in
            print("Preview: Plan Generated with config: \(config)")
        }
    }
}
