import SwiftUI
import SwiftData
import Foundation // Added for general type resolution
import UIKit

// MARK: - Supporting Enums and Structs





struct PlanConfiguration {
    var goal: FitnessGoal = .fatLoss
    var targetWeight: Double = 65.0
    var workoutDurationPerSession: Int = 45
    var workoutFrequency: Int = 3
    var trainingDays: Set<Weekday> = []
    var sleepDurationTarget: Int = 8
    var planDuration: Int = 30
    var experienceLevel: ExperienceLevel = .beginner
    var professionalModeEnabled: Bool = false
}

private extension ClosedRange where Bound: Comparable {
    func intersection(with other: ClosedRange<Bound>) -> ClosedRange<Bound>? {
        let lower = max(lowerBound, other.lowerBound)
        let upper = min(upperBound, other.upperBound)
        return lower <= upper ? lower...upper : nil
    }
}

private enum WeightGoalDirection: String {
    case gain = "增重"
    case lose = "减重"
    case maintain = "维持"
    case none = "未设定"

    static let toleranceKg: Double = 0.2

    static func expected(for goal: FitnessGoal) -> WeightGoalDirection {
        switch goal {
        case .fatLoss: return .lose
        case .muscleGain: return .gain
        case .healthImprovement: return .maintain
        }
    }

    static func actual(delta: Double) -> WeightGoalDirection {
        if delta > WeightGoalDirection.toleranceKg { return .gain }
        if delta < -WeightGoalDirection.toleranceKg { return .lose }
        if abs(delta) <= WeightGoalDirection.toleranceKg { return .maintain }
        return .none
    }

    var description: String { rawValue }
}

private struct WeightGoalValidation {
    enum Status {
        case missingBaseline
        case directionMismatch(expected: WeightGoalDirection, actual: WeightGoalDirection)
        case belowMinimum(ratio: Double, minimum: Double)
        case aboveMaximum(ratio: Double, maximum: Double)
        case valid(ratio: Double)
    }

    let status: Status
    let ratio: Double?
    let allowedRange: ClosedRange<Double>
    let expectedDirection: WeightGoalDirection
    let actualDirection: WeightGoalDirection

    var allowsProgress: Bool {
        switch status {
        case .valid, .missingBaseline:
            return true
        default:
            return false
        }
    }

    var isBaselineMissing: Bool {
        if case .missingBaseline = status { return true }
        return false
    }

    static func evaluate(
        baselineWeight: Double?,
        targetWeight: Double,
        goal: FitnessGoal,
        professionalMode: Bool
    ) -> WeightGoalValidation {
        let expected = WeightGoalDirection.expected(for: goal)
        let range = ratioRange(for: goal, professionalMode: professionalMode)
        guard let baseline = baselineWeight, baseline > 0 else {
            return WeightGoalValidation(
                status: .missingBaseline,
                ratio: nil,
                allowedRange: range,
                expectedDirection: expected,
                actualDirection: .none
            )
        }

        let delta = targetWeight - baseline
        let actual = WeightGoalDirection.actual(delta: delta)
        let ratio = abs(delta) / baseline

        if expected == .lose && actual == .gain {
            return WeightGoalValidation(
                status: .directionMismatch(expected: expected, actual: actual),
                ratio: ratio,
                allowedRange: range,
                expectedDirection: expected,
                actualDirection: actual
            )
        }

        if expected == .gain && actual == .lose {
            return WeightGoalValidation(
                status: .directionMismatch(expected: expected, actual: actual),
                ratio: ratio,
                allowedRange: range,
                expectedDirection: expected,
                actualDirection: actual
            )
        }

        if range.lowerBound > 0 && ratio + 0.0001 < range.lowerBound {
            return WeightGoalValidation(
                status: .belowMinimum(ratio: ratio, minimum: range.lowerBound),
                ratio: ratio,
                allowedRange: range,
                expectedDirection: expected,
                actualDirection: actual
            )
        }

        if ratio - 0.0001 > range.upperBound {
            return WeightGoalValidation(
                status: .aboveMaximum(ratio: ratio, maximum: range.upperBound),
                ratio: ratio,
                allowedRange: range,
                expectedDirection: expected,
                actualDirection: actual
            )
        }

        return WeightGoalValidation(
            status: .valid(ratio: ratio),
            ratio: ratio,
            allowedRange: range,
            expectedDirection: expected,
            actualDirection: actual
        )
    }
}

private struct WeeklyPaceValidation {
    enum Status {
        case missingBaseline
        case directionMismatch(expected: WeightGoalDirection, actual: WeightGoalDirection)
        case tooSlow(rate: Double, minimum: Double)
        case tooFast(rate: Double, maximum: Double)
        case valid(rate: Double)
    }

    let status: Status
    let signedWeeklyChange: Double?
    let allowedRange: ClosedRange<Double>
    let expectedDirection: WeightGoalDirection
    let actualDirection: WeightGoalDirection

    var allowsProgress: Bool {
        switch status {
        case .valid, .missingBaseline:
            return true
        default:
            return false
        }
    }

    static func evaluate(
        baselineWeight: Double?,
        targetWeight: Double,
        planDuration: Int,
        goal: FitnessGoal,
        professionalMode: Bool
    ) -> WeeklyPaceValidation {
        let expected = WeightGoalDirection.expected(for: goal)
        let range = weeklyRange(for: goal, professionalMode: professionalMode)

        guard let baseline = baselineWeight, baseline > 0, planDuration > 0 else {
            return WeeklyPaceValidation(
                status: .missingBaseline,
                signedWeeklyChange: nil,
                allowedRange: range,
                expectedDirection: expected,
                actualDirection: .none
            )
        }

        let delta = targetWeight - baseline
        let actual = WeightGoalDirection.actual(delta: delta)
        let weeklyChange = delta / Double(planDuration) * 7.0
        let magnitude = abs(weeklyChange)

        if expected == .lose && actual == .gain {
            return WeeklyPaceValidation(
                status: .directionMismatch(expected: expected, actual: actual),
                signedWeeklyChange: weeklyChange,
                allowedRange: range,
                expectedDirection: expected,
                actualDirection: actual
            )
        }

        if expected == .gain && actual == .lose {
            return WeeklyPaceValidation(
                status: .directionMismatch(expected: expected, actual: actual),
                signedWeeklyChange: weeklyChange,
                allowedRange: range,
                expectedDirection: expected,
                actualDirection: actual
            )
        }

        if range.lowerBound > 0 && magnitude + 0.0001 < range.lowerBound {
            return WeeklyPaceValidation(
                status: .tooSlow(rate: magnitude, minimum: range.lowerBound),
                signedWeeklyChange: weeklyChange,
                allowedRange: range,
                expectedDirection: expected,
                actualDirection: actual
            )
        }

        if magnitude - 0.0001 > range.upperBound {
            return WeeklyPaceValidation(
                status: .tooFast(rate: magnitude, maximum: range.upperBound),
                signedWeeklyChange: weeklyChange,
                allowedRange: range,
                expectedDirection: expected,
                actualDirection: actual
            )
        }

        return WeeklyPaceValidation(
            status: .valid(rate: magnitude),
            signedWeeklyChange: weeklyChange,
            allowedRange: range,
            expectedDirection: expected,
            actualDirection: actual
        )
    }
}

private enum ConfirmationGateReason: Identifiable {
    case paceRange

    var id: Int { 0 }

    var title: String {
        switch self {
        case .paceRange:
            return "每周变化不在安全范围"
        }
    }

    var message: String {
        switch self {
        case .paceRange:
            return "当前计划周期会导致每周变化超出健康区间，建议延长/缩短周期或重新设定目标体重。"
        }
    }
}

private func ratioRange(for goal: FitnessGoal, professionalMode: Bool) -> ClosedRange<Double> {
    switch goal {
    case .fatLoss:
        return professionalMode ? 0.03...0.15 : 0.05...0.10
    case .muscleGain:
        return professionalMode ? 0.03...0.12 : 0.05...0.10
    case .healthImprovement:
        return professionalMode ? 0.0...0.05 : 0.0...0.02
    }
}

private func weeklyRange(for goal: FitnessGoal, professionalMode: Bool) -> ClosedRange<Double> {
    switch goal {
    case .fatLoss:
        return professionalMode ? 0.3...1.5 : 0.5...1.0
    case .muscleGain:
        return professionalMode ? 0.2...0.7 : 0.25...0.5
    case .healthImprovement:
        return professionalMode ? 0.0...0.35 : 0.0...0.2
    }
}

// MARK: - Main View

struct PlanSetupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Query(filter: #Predicate<Plan> { $0.status == "active" }, sort: \.startDate, order: .reverse)
    private var activePlans: [Plan]
    @Query(sort: \HealthMetric.date, order: .forward)
    private var allMetrics: [HealthMetric]
    
    @State private var config = PlanConfiguration()
    @State private var currentStep = 0
    @State private var isLoadingPlan = false // NEW STATE VARIABLE
    @State private var loadingStartTime: Date?
    @State private var hasSeededExistingPlan = false
    @State private var confirmationGateReason: ConfirmationGateReason?
    
    var onComplete: @Sendable (PlanConfiguration) async -> Void

    private let totalSteps = 9

    private var latestWeightMetric: Double? {
        allMetrics.filter { $0.type == .weight }.last?.value
    }

    private var currentBaselineWeight: Double? {
        latestWeightMetric ?? profileViewModel.userProfile.currentWeight
    }

    private var baselineMissing: Bool {
        currentBaselineWeight == nil
    }

    private var weightValidation: WeightGoalValidation {
        WeightGoalValidation.evaluate(
            baselineWeight: currentBaselineWeight,
            targetWeight: config.targetWeight,
            goal: config.goal,
            professionalMode: config.professionalModeEnabled
        )
    }

    private var paceValidation: WeeklyPaceValidation {
        WeeklyPaceValidation.evaluate(
            baselineWeight: currentBaselineWeight,
            targetWeight: config.targetWeight,
            planDuration: config.planDuration,
            goal: config.goal,
            professionalMode: config.professionalModeEnabled
        )
    }

    private var canEnterConfirmation: Bool {
        paceValidation.allowsProgress
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("为你定制专属训练方案")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    Spacer()
                }
                .opacity(currentStep == 8 ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: currentStep)

//                    ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
//                        .progressViewStyle(.linear)
//                        .padding(.horizontal)
//                        .padding(.top, 10)
                // Add some padding from the top
                TabView(selection: stepSelection) {
                    GoalStepView(selectedGoal: $config.goal, currentStep: $currentStep).tag(0)
                    TargetWeightStepView(
                        targetWeight: $config.targetWeight,
                        professionalModeEnabled: $config.professionalModeEnabled,
                        currentWeight: currentBaselineWeight,
                        goal: config.goal,
                        validation: weightValidation,
                        currentStep: $currentStep
                    ).tag(1)
                    ExperienceLevelStepView(experienceLevel: $config.experienceLevel, currentStep: $currentStep).tag(2)
                    CycleStepView(
                        planDuration: $config.planDuration,
                        baselineWeight: currentBaselineWeight,
                        targetWeight: config.targetWeight,
                        goal: config.goal,
                        professionalModeEnabled: config.professionalModeEnabled,
                        validation: paceValidation
                    ).tag(3)
                    DurationStepView(duration: $config.workoutDurationPerSession, currentStep: $currentStep).tag(4)
                    LifestyleStepView(sleepTarget: $config.sleepDurationTarget).tag(5)
                    ScheduleStepView(frequency: $config.workoutFrequency, selectedDays: $config.trainingDays).tag(6)
                    ConfirmationStepView(
                        config: config,
                        baselineWeight: currentBaselineWeight,
                        weightValidation: weightValidation,
                        paceValidation: paceValidation,
                        currentStep: $currentStep,
                        onComplete: completePlanGeneration,
                        isLoadingPlan: $isLoadingPlan,
                        loadingStartTime: $loadingStartTime
                    ).tag(7)
                    PlanGenerationAnimationStepView(isLoadingPlan: $isLoadingPlan)
                        .tag(8)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentStep) { _, newValue in
                    if newValue == 8 && !isLoadingPlan {
                        withAnimation {
                            currentStep = max(0, min(7, newValue - 1))
                        }
                    }
                }
            }
            .navigationTitle(currentStep == 8 ? "" : "制定新计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(currentStep == 8 ? .hidden : .visible, for: .navigationBar)
            .toolbarBackground(currentStep == 8 ? .hidden : .visible, for: .navigationBar)
        }
        .onAppear {
            seedConfigIfNeeded()
            if baselineMissing {
                config.professionalModeEnabled = false
            }
        }
        .onChange(of: baselineMissing) { _, missing in
            if missing {
                config.professionalModeEnabled = false
            }
        }
        .alert(item: $confirmationGateReason) { reason in
            Alert(
                title: Text(reason.title),
                message: Text(reason.message),
                dismissButton: .default(Text("好的"))
            )
        }
    }

    private func seedConfigIfNeeded() {
        guard !hasSeededExistingPlan else { return }
        if let activePlan = activePlans.first {
            config.goal = activePlan.planGoal.fitnessGoal
            config.targetWeight = activePlan.planGoal.targetWeight
            config.planDuration = activePlan.duration
        } else if let experience = profileViewModel.userProfile.experienceLevel {
            config.experienceLevel = experience
        }
        hasSeededExistingPlan = true
    }

    private var stepSelection: Binding<Int> {
        Binding(
            get: { currentStep },
            set: { newValue in
                let clamped = max(0, min(newValue, totalSteps - 1))
                if currentStep == 8 && clamped != currentStep {
                    return
                }
                if clamped == 7 && !canEnterConfirmation {
                    if !paceValidation.allowsProgress {
                        withAnimation {
                            currentStep = 3
                        }
                        confirmationGateReason = .paceRange
                    }
                    return
                }
                guard !(currentStep == 7 && clamped > currentStep && !isLoadingPlan) else { return }
                currentStep = clamped
            }
        )
    }

    private func completePlanGeneration() async {
        let start = loadingStartTime ?? Date()
        await onComplete(config)
        let elapsed = Date().timeIntervalSince(start)
        let minimumDuration: TimeInterval = 5
        if elapsed < minimumDuration {
            let remaining = UInt64((minimumDuration - elapsed) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: remaining)
        }
        await MainActor.run {
            isLoadingPlan = false
            loadingStartTime = nil
            dismiss()
        }
    }
}

// MARK: - Plan Generation Animation Step

private struct PlanGenerationAnimationStepView: View {
    @Binding var isLoadingPlan: Bool
    @State private var animationStarted = false
    @State private var collapse = false
    @State private var showCards = false
    @State private var cardStages: [Bool] = Array(repeating: false, count: PlanCardDescriptor.presets.count)
    @State private var messageIndex = 0

    private let messages = [
        "锁定你的训练目标与热情",
        "平衡训练节奏与恢复窗口",
        "打磨每一张计划卡片"
    ]

    var body: some View {
        ZStack {
            if isLoadingPlan {
                animationContent
                    .overlay(
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0))
                    )
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                    .transition(.opacity)
            }
        }
        .onAppear {
            prepareForAnimationIfNeeded()
        }
        .onChange(of: isLoadingPlan) { _, newValue in
            if newValue {
                prepareForAnimationIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var animationContent: some View {
        VStack(spacing: 24) {
//            Spacer()
            AnimatedBrandOrbit(collapse: collapse)
                .frame(width: 240, height: 240)

            if showCards {
                AnimatedPlanCards(cardStages: $cardStages)
                    .frame(maxWidth: .infinity)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

//            Spacer()
        }
        .offset(y: 30)
    }

    private func prepareForAnimationIfNeeded() {
        guard isLoadingPlan else { return }
        resetAnimationState()
        startAnimationPhasesIfNeeded()
    }

    private func resetAnimationState() {
        animationStarted = false
        collapse = false
        showCards = false
        cardStages = Array(repeating: false, count: PlanCardDescriptor.presets.count)
        messageIndex = 0
    }

    private func startAnimationPhasesIfNeeded() {
        guard !animationStarted else { return }
        animationStarted = true

        Task {
            try? await Task.sleep(nanoseconds: 650_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.9)) {
                    collapse = true
                }
            }

            try? await Task.sleep(nanoseconds: 420_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.85, blendDuration: 0.4)) {
                    showCards = true
                }
            }

            for index in cardStages.indices {
                try? await Task.sleep(nanoseconds: 240_000_000)
                await MainActor.run {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred(intensity: 0.7)

                    withAnimation(.spring(response: 0.6, dampingFraction: 0.82, blendDuration: 0.25)) {
                        cardStages[index] = true
                    }

                    if index + 1 < messages.count {
                        messageIndex = index + 1
                    } else {
                        messageIndex = messages.count - 1
                    }
                }
            }
        }
    }
}

private struct AnimatedBrandOrbit: View {
    let collapse: Bool
    @State private var rotate = false
    @State private var pulse = false

    var body: some View {
        GeometryReader { geometry in
            let baseSize = min(geometry.size.width, geometry.size.height)
            let radius = collapse ? baseSize * 0.14 : baseSize * 0.42

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.22))
                    .scaleEffect(pulse ? 1.08 : 0.96)
                    .blur(radius: collapse ? 14 : 22)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)

                Circle()
                    .stroke(Color.white.opacity(0.14), lineWidth: 2)
                    .scaleEffect(collapse ? 0.58 : 1.0)
                    .animation(.easeInOut(duration: 0.8), value: collapse)

                ZStack {
                    ForEach(Array(BrandGlyphType.allCases.enumerated()), id: \.offset) { index, type in
                        BrandGlyph(type: type)
                            .frame(width: baseSize * 0.36, height: baseSize * 0.36)
                            .offset(orbitOffset(for: index, radius: radius))
                            .scaleEffect(collapse ? 0.45 : 1.0)
                            .opacity(collapse ? 0.0 : 1.0)
                            .animation(.easeInOut(duration: 0.8), value: collapse)
                    }
                }
                .rotationEffect(.degrees(rotate ? 360 : 0))
                .animation(.linear(duration: 6.5).repeatForever(autoreverses: false), value: rotate)

                BrandCoreNucleus(expanded: collapse)
                    .frame(width: baseSize * (collapse ? 0.92 : 0.62), height: baseSize * (collapse ? 0.92 : 0.62))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onAppear {
            rotate = true
            pulse = true
        }
    }

    private func orbitOffset(for index: Int, radius: CGFloat) -> CGSize {
        let angle = Double(index) * (360.0 / Double(BrandGlyphType.allCases.count)) - 90
        let radians = angle * .pi / 180.0
        let x = radius * CGFloat(cos(radians))
        let y = radius * CGFloat(sin(radians))
        return CGSize(width: x, height: y)
    }
}

private struct BrandCoreNucleus: View {
    let expanded: Bool
    @State private var shimmer = false

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.28, green: 0.35, blue: 0.98), Color(red: 0.08, green: 0.09, blue: 0.26)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        .blur(radius: 1)
                )
                .shadow(color: Color.accentColor.opacity(0.3), radius: 18, x: 0, y: 16)

            if expanded {
                VStack(spacing: 10) {
                    Capsule()
                        .fill(Color.white.opacity(0.24))
                        .frame(height: 10)
                    Capsule()
                        .fill(Color.white.opacity(0.4))
                        .frame(height: 10)
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: 10)
                }
                .padding(32)
                .transition(.scale.combined(with: .opacity))
            } else {
                Circle()
                    .fill(Color.white.opacity(0.16))
                    .scaleEffect(shimmer ? 1.08 : 0.92)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: shimmer)
                    .padding(28)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: expanded)
        .onAppear {
            shimmer = true
        }
    }
}

private enum BrandGlyphType: CaseIterable {
    case goal
    case rhythm
    case experience

    var gradient: [Color] {
        switch self {
        case .goal:
            return [Color(red: 0.30, green: 0.72, blue: 0.98), Color(red: 0.18, green: 0.45, blue: 0.88)]
        case .rhythm:
            return [Color(red: 0.98, green: 0.61, blue: 0.43), Color(red: 0.89, green: 0.29, blue: 0.45)]
        case .experience:
            return [Color(red: 0.66, green: 0.51, blue: 0.99), Color(red: 0.35, green: 0.29, blue: 0.83)]
        }
    }

    var shadowColor: Color {
        switch self {
        case .goal: return Color(red: 0.12, green: 0.41, blue: 0.83)
        case .rhythm: return Color(red: 0.77, green: 0.22, blue: 0.35)
        case .experience: return Color(red: 0.28, green: 0.20, blue: 0.64)
        }
    }

    @ViewBuilder
    var illustration: some View {
        switch self {
        case .goal:
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 48, height: 48)
                    .offset(y: 14)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 6, height: 46)
                    .offset(x: -6, y: -4)
                Triangle()
                    .fill(Color.white)
                    .frame(width: 36, height: 28)
                    .offset(x: 10, y: -10)
            }
        case .rhythm:
            ZStack {
                WaveShape()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 62, height: 38)
                    .offset(y: 4)
                HStack(spacing: 6) {
                    Capsule()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 8, height: 34)
                    Capsule()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 8, height: 46)
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 8, height: 28)
                }
            }
        case .experience:
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 58)
                StarShape(points: 5)
                    .fill(Color.white)
                    .frame(width: 46, height: 46)
                    .shadow(color: Color.white.opacity(0.6), radius: 6, x: 0, y: 4)
            }
        }
    }
}

private struct BrandGlyph: View {
    let type: BrandGlyphType

    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(LinearGradient(colors: type.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: type.shadowColor.opacity(0.35), radius: 14, x: 0, y: 12)
            .overlay {
                type.illustration
            }
    }
}

private struct AnimatedPlanCards: View {
    @Binding var cardStages: [Bool]

    var body: some View {
        VStack(spacing: 14) {
            ForEach(Array(PlanCardDescriptor.presets.enumerated()), id: \.offset) { index, card in
                AnimatedPlanCardView(card: card, isActive: index < cardStages.count ? cardStages[index] : false)
            }
        }
    }
}

private struct AnimatedPlanCardView: View {
    let card: PlanCardDescriptor
    let isActive: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(LinearGradient(colors: card.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(card.detail)
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical,22)
                .padding(.horizontal, 22)
            )
            .overlay(alignment: .bottomTrailing) {
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 54, height: 12)
                    .offset(x: -18, y: -16)
                    .blur(radius: 0.2)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive ? 0 : 50)
            .rotationEffect(.degrees(isActive ? 0 : 12))
            .animation(.spring(response: 0.7, dampingFraction: 0.78, blendDuration: 0.3), value: isActive)
    }
}

private struct PlanCardDescriptor {
    let title: String
    let detail: String
    let colors: [Color]

    static let presets: [PlanCardDescriptor] = [
        PlanCardDescriptor(
            title: "智能聚焦核心目标",
            detail: "结合你的体能水平与目标强度，优先锁定训练侧重点。",
            colors: [Color(red: 0.27, green: 0.62, blue: 0.99), Color(red: 0.12, green: 0.36, blue: 0.86)]
        ),
        PlanCardDescriptor(
            title: "编排周期节奏",
            detail: "动态调整训练与恢复的比例，打造可持续的节奏。",
            colors: [Color(red: 0.99, green: 0.58, blue: 0.45), Color(red: 0.87, green: 0.28, blue: 0.44)]
        ),
        PlanCardDescriptor(
            title: "雕刻执行卡片",
            detail: "为每日任务生成品牌插画风的训练卡，保证一目了然。",
            colors: [Color(red: 0.66, green: 0.50, blue: 0.99), Color(red: 0.36, green: 0.32, blue: 0.85)]
        )
    ]
}

// MARK: - Animated Icon

private struct ExperienceLevelStepView: View {
    @Binding var experienceLevel: ExperienceLevel
    @Binding var currentStep: Int

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            AnimatedRunningIcon() // Reusing existing icon
            Spacer().frame(height: 30)
            Text("您的训练经验水平是？").font(.largeTitle).bold().multilineTextAlignment(.center)

            Picker("经验水平", selection: $experienceLevel) {
                ForEach(ExperienceLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)

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
            .cornerRadius(32)
        }.padding()
    }
}
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
    @Binding var professionalModeEnabled: Bool
    let currentWeight: Double?
    let goal: FitnessGoal
    let validation: WeightGoalValidation
    @Binding var currentStep: Int
    private let sliderConfiguration = TargetWeightSliderConfiguration.planSetup
    @State private var showProfessionalAlert = false

    private var baselineWeight: Double? { currentWeight }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            AnimatedRunningIcon()
            Spacer()
            Text("您的目标体重是？")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)

            if let baseline = baselineWeight {
                currentWeightInfo(for: baseline)
            }
            
            TargetWeightSlider(
                weight: $targetWeight,
                baselineWeight: targetWeight,
                configuration: sliderConfiguration
            )

            safetyBanner
                .frame(maxWidth: .infinity, alignment: .leading)

            professionalToggle

            guidelineBlock
                .frame(maxWidth: .infinity, alignment: .leading)

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
                .cornerRadius(32)

        }
        .padding()
        .onAppear {
            clampTargetToAllowedRangeIfNeeded()
        }
        .onChange(of: allowedWeightRange) { _, _ in
            clampTargetToAllowedRangeIfNeeded()
        }
        .alert("确认开启专业模式？", isPresented: $showProfessionalAlert) {
            Button("暂不", role: .cancel) {
                professionalModeEnabled = false
            }
            Button("确认开启", role: .destructive) {
                professionalModeEnabled = true
            }
        } message: {
            Text("仅在医生或教练的明确指导下开启。专业模式会放宽目标限制，也会提升潜在风险。")
        }
    }

    private func currentWeightInfo(for weight: Double) -> some View {
        VStack(spacing: 4) {
            Text("最近记录体重")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(weight, specifier: "%.1f") kg")
                .font(.title2.bold())
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
    
    private var compactGoalRange: ClosedRange<Double>? {
        guard let baseline = baselineWeight else { return nil }
        let offsets = goalOffsets(for: baseline)
        let lower = max(sliderConfiguration.minimumWeight, baseline - offsets.down)
        let upper = min(sliderConfiguration.maximumWeight, baseline + offsets.up)
        guard lower < upper else { return nil }
        return lower...upper
    }
    
    private var allowedWeightRange: ClosedRange<Double>? {
        if let compactGoalRange {
            return compactGoalRange
        }
        return sliderConfiguration.minimumWeight...sliderConfiguration.maximumWeight
    }

    private func goalOffsets(for baseline: Double) -> (down: Double, up: Double) {
        switch goal {
        case .fatLoss:
            let down = max(5, baseline * 0.1)
            let up: Double = 0
            return (down: down, up: up)
        case .muscleGain:
            let down: Double = 0
            let up = min(max(3, baseline * 0.08), 10)
            return (down: down, up: up)
        case .healthImprovement:
            let delta = max(2, baseline * 0.02)
            return (down: delta, up: delta)
        }
    }
    
    private func clampTargetToAllowedRangeIfNeeded() {
        guard let allowedWeightRange else { return }
        if !allowedWeightRange.contains(targetWeight) {
            targetWeight = targetWeight.clamped(to: allowedWeightRange)
        }
    }

    private var safetyBanner: some View {
        let info = safetyMessage
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: info.icon)
                .font(.subheadline.weight(.bold))
                .foregroundColor(info.color)
            Text(info.text)
                .font(.caption)
                .foregroundColor(info.color)
        }
        .padding(12)
        .background(info.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var safetyMessage: (text: String, color: Color, icon: String) {
        switch validation.status {
        case .missingBaseline:
            return (
                "尚未录入当前体重，暂以默认值展示。建议先在记录页称重，以便严格评估阶段目标。",
                Color.secondary,
                "info.circle"
            )
        case .directionMismatch(let expected, let actual):
            return (
                "当前调整为“\(actual.description)”方向，与目标「\(expected.description)」不符，请先修改目标体重方向。",
                Color.red,
                "exclamationmark.triangle.fill"
            )
        case .belowMinimum(let ratio, let minimum):
            return (
                String(format: "阶段目标约 %.1f%%，低于建议起点 %@，可适度放宽或拆分到更长周期。", ratio * 100, formattedPercent(minimum)),
                Color.orange,
                "exclamationmark.triangle.fill"
            )
        case .aboveMaximum(let ratio, let maximum):
            let action = validation.expectedDirection == .lose ? "减重" : "增重"
            return (
                String(format: "阶段目标约 %.1f%%，超出建议上限 %@，易造成过快%@，建议拆分阶段或开启专业模式并听从医生指示。", ratio * 100, formattedPercent(maximum), action),
                Color.red,
                "exclamationmark.triangle.fill"
            )
        case .valid(let ratio):
            let direction = validation.expectedDirection == .maintain ? "维持" : validation.expectedDirection.description
            return (
                String(format: "%@阶段目标约 %.1f%%，位于建议区间 %@。", direction, ratio * 100, allowedRangeDescription),
                Color.green,
                "checkmark.circle.fill"
            )
        }
    }

    private var professionalToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { professionalModeEnabled },
                set: { newValue in
                    if newValue {
                        showProfessionalAlert = true
                    } else {
                        professionalModeEnabled = false
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("已获得专业建议")
                        .font(.subheadline.bold())
                    Text("医生指示、竞技备赛或特殊需求可开启专业模式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .disabled(validation.isBaselineMissing)
            .tint(.accentColor)

            if validation.isBaselineMissing {
                Text("补充一次体重记录后即可开启专业模式。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if professionalModeEnabled {
                Text("已放宽刻度限制，请确保专业人士全程跟进。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("默认按照健康区间（\(allowedRangeDescription)）严格控制目标。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var guidelineBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("专业健康标准参考（WHO / CDC）：")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
            Text(goalSpecificGuideline)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 4)
    }

    private var goalSpecificGuideline: String {
        switch goal {
        case .fatLoss:
            return "减重：建议每周减 0.5–1 kg，对应阶段目标 5%–10%。"
        case .muscleGain:
            return "增重：建议每周增 0.25–0.5 kg，阶段目标约 5%（最高 10%）。"
        case .healthImprovement:
            return "维持：建议体重波动控制在 ±2%，更关注训练与饮食。"
        }
    }

    private var allowedRangeDescription: String {
        if validation.allowedRange.lowerBound <= 0.0001 {
            return "±" + formattedPercent(validation.allowedRange.upperBound)
        }
        return formattedPercent(validation.allowedRange.lowerBound) + "–" + formattedPercent(validation.allowedRange.upperBound)
    }

    private func formattedPercent(_ value: Double) -> String {
        let percent = value * 100
        let rounded = percent.rounded()
        if abs(percent - rounded) < 0.05 {
            return String(format: "%.0f%%", rounded)
        }
        return String(format: "%.1f%%", percent)
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
    let baselineWeight: Double?
    let targetWeight: Double
    let goal: FitnessGoal
    let professionalModeEnabled: Bool
    let validation: WeeklyPaceValidation

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            AnimatedRunningIcon()
            Spacer().frame(height: 30)
            Text("计划总周期？")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            Text("选择整个计划的总时长 (天)")
                .font(.title2)
                .bold()
            Slider(
                value: .init(get: { Double(planDuration) }, set: { planDuration = Int($0) }),
                in: 7...90,
                step: 1
            )
            .padding(.horizontal)
            Text("\(planDuration) 天")
                .font(.largeTitle)
                .bold()

            validationBanner
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text("预计每周变化：\(weeklyChangeDisplay)")
                    .font(.body.weight(.semibold))
                Text("建议范围：\(weeklyAllowedRangeText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(goalPaceGuideline)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if professionalModeEnabled {
                    Text("已启用专业模式，速度校验已放宽，请确保专业人士全程监督。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
            Text("滑动或点击继续下一步")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var validationBanner: some View {
        let info = validationMessage
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: info.icon)
                .font(.subheadline.weight(.bold))
                .foregroundColor(info.color)
            Text(info.text)
                .font(.caption)
                .foregroundColor(info.color)
        }
        .padding(12)
        .background(info.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var validationMessage: (text: String, color: Color, icon: String) {
        switch validation.status {
        case .missingBaseline:
            return (
                "还未同步当前体重，暂以默认值估算周速度。建议记录一次体重后再评估周期。",
                Color.secondary,
                "info.circle"
            )
        case .directionMismatch(let expected, let actual):
            return (
                "周期设置将导致“\(actual.description)”方向，但当前目标为「\(expected.description)」，请返回上一页调整目标体重。",
                Color.red,
                "exclamationmark.triangle.fill"
            )
        case .tooSlow(let rate, let minimum):
            return (
                String(format: "约 %.2f kg/周，低于建议起点 %@，可适当缩短周期或加大阶段目标。", rate, formattedRate(minimum)),
                Color.orange,
                "exclamationmark.triangle.fill"
            )
        case .tooFast(let rate, let maximum):
            return (
                String(format: "约 %.2f kg/周，超出建议上限 %@，建议延长周期或拆分目标，避免超速。", rate, formattedRate(maximum)),
                Color.red,
                "exclamationmark.triangle.fill"
            )
        case .valid(let rate):
            return (
                String(format: "约 %.2f kg/周，位于建议范围 %@。", rate, weeklyAllowedRangeText),
                Color.green,
                "checkmark.circle.fill"
            )
        }
    }

    private var weeklyChangeDisplay: String {
        guard let change = validation.signedWeeklyChange else {
            return "待录入体重后计算"
        }
        return String(format: "%+.2f kg/周", change)
    }

    private var weeklyAllowedRangeText: String {
        if validation.allowedRange.lowerBound <= 0.0001 {
            return "≤\(formattedRate(validation.allowedRange.upperBound)) kg/周"
        }
        return "\(formattedRate(validation.allowedRange.lowerBound))–\(formattedRate(validation.allowedRange.upperBound)) kg/周"
    }

    private var goalPaceGuideline: String {
        switch goal {
        case .fatLoss:
            return "推荐减重速度 0.5–1.0 kg/周，超过该区间需医生指导。"
        case .muscleGain:
            return "推荐增肌速度 0.25–0.5 kg/周，速度过快易增加脂肪。"
        case .healthImprovement:
            return "维持目标以习惯养成为主，体重波动宜控制在每周 ≤\(formattedRate(validation.allowedRange.upperBound)) kg。"
        }
    }

    private func formattedRate(_ value: Double) -> String {
        let roundedToOne = (value * 10).rounded() / 10
        if abs(value - roundedToOne) < 0.01 {
            return String(format: "%.1f", roundedToOne)
        }
        return String(format: "%.2f", value)
    }
}

private struct ConfirmationStepView: View {
    let config: PlanConfiguration
    let baselineWeight: Double?
    let weightValidation: WeightGoalValidation
    let paceValidation: WeeklyPaceValidation
    @Binding var currentStep: Int
    let onComplete: () async -> Void
    @Binding var isLoadingPlan: Bool // NEW BINDING
    @Binding var loadingStartTime: Date?
    private let columns = Array(repeating: GridItem(.flexible(minimum: 120), spacing: 4), count: 3)
    private let dragThreshold: CGFloat = 45
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                ZStack {
                    ScrollView {
                        VStack(alignment: .center, spacing: 12) {
                            baselineWarning
                            professionalModeBanner
                            paceWarning
                            HStack(spacing: 15) {
                                Image(systemName: "flag.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 30)

                                VStack(alignment: .leading) {
                                    Text("主要目标")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                        .padding(10)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(20)
                                    Text(config.goal.rawValue)
                                        .font(.system(size: 28))
                                        .fontWeight(.regular)
                                }

                                Spacer()
                            }
                            .padding()
                            .cornerRadius(32)
                            ConfirmationCard(iconName: "person.fill", label: "经验水平", value: config.experienceLevel.rawValue)
                            ConfirmationCard(iconName: "scalemass.fill", label: "目标体重", value: String(format: "%.0f kg", config.targetWeight))
                            LazyVGrid(columns: columns, spacing: 0) {
                                ConfirmationCard(iconName: "calendar", label: "每周频率", value: "\(config.workoutFrequency) 天")
                                    .frame(maxWidth: .infinity)
                                ConfirmationCard(iconName: "hourglass", label: "每次时长", value: "\(config.workoutDurationPerSession) 分钟")
                                    .frame(maxWidth: .infinity)
                                ConfirmationCard(iconName: "bed.double.fill", label: "睡眠目标", value: "\(config.sleepDurationTarget) 小时")
                                    .frame(maxWidth: .infinity)
                            }
                            HStack(spacing: 12) {
                                ConfirmationCard(iconName: "calendar.badge.clock", label: "计划周期", value: "\(config.planDuration) 天")
                                ConfirmationCard(iconName: "speedometer", label: "预计每周变化", value: weeklyChangeDisplay)
                            }
                            ConfirmationCard(
                                iconName: "checklist",
                                label: "训练日",
                                value: config.trainingDays.isEmpty
                                    ? "未指定"
                                    : config.trainingDays
                                        .sorted { $0.displayOrder < $1.displayOrder }
                                        .map { $0.rawValue }
                                        .joined(separator: ", ")
                            )
                        }
                        .padding()
                        .frame(minHeight: geometry.size.height, alignment: .top)
                    }
                    if !isLoadingPlan {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in }
                                    .onEnded { value in
                                        guard value.translation.width > dragThreshold else { return }
                                        withAnimation(.easeInOut) {
                                            currentStep = max(0, currentStep - 1)
                                        }
                                    }
                            )
                    }
                }

                Button(action: {
                    guard !isLoadingPlan else { return }
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    loadingStartTime = Date()
                    isLoadingPlan = true
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = 8
                    }
                    Task {
                        await onComplete() // Trigger plan generation
                    }
                }) {
                    Text("生成计划")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(32)
                }
                .padding(.horizontal)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 12))
            }
            .frame(minHeight: geometry.size.height, alignment: .top)
        }
    }

    private var weeklyChangeDisplay: String {
        guard let change = paceValidation.signedWeeklyChange else {
            return "待录入体重"
        }
        return String(format: "%+.2f kg/周", change)
    }

    @ViewBuilder
    private var baselineWarning: some View {
        if baselineWeight == nil {
            warningRow(
                icon: "exclamationmark.triangle.fill",
                color: .orange,
                text: "尚未录入当前体重，已暂用默认值。建议先在记录页完成一次称重，以便精准评估目标与周期。"
            )
        }
    }

    @ViewBuilder
    private var paceWarning: some View {
        if case .missingBaseline = paceValidation.status, baselineWeight == nil {
            warningRow(
                icon: "info.circle",
                color: .secondary,
                text: "每周速度需等记录体重后才能精准计算，暂不做强校验。"
            )
        }
    }

    @ViewBuilder
    private var professionalModeBanner: some View {
        if config.professionalModeEnabled {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "cross.case.fill")
                        .foregroundColor(.white)
                    Text("已启用专业模式")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                }
                Text("目标范围与周速度校验已放宽，请确保全程由医生或教练监督。")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                Button {
                    withAnimation {
                        currentStep = 2
                    }
                } label: {
                    Text("返回目标页退出专业模式")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white, in: Capsule())
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
        }
    }

    private func warningRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundColor(color)
            Text(text)
                .font(.caption)
                .foregroundColor(color)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ConfirmationCard: View {
    let iconName: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.headline)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(32)
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
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(32)
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

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        let step = max(rect.width / 24, 1)
        var x = rect.minX
        while x <= rect.maxX {
            let progress = Double((x - rect.minX) / rect.width)
            let y = rect.midY + CGFloat(sin(progress * .pi * 2)) * rect.height * 0.25
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct StarShape: Shape {
    let points: Int

    func path(in rect: CGRect) -> Path {
        guard points >= 2 else { return Path() }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.48
        var path = Path()

        for index in 0..<(points * 2) {
            let isOuterPoint = index.isMultiple(of: 2)
            let angle = Double(index) * .pi / Double(points) - .pi / 2
            let radius = isOuterPoint ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

struct PlanSetupView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Plan.self, configurations: config)

        return PlanSetupView { generatedConfig in
            await MainActor.run {
                print("Preview: Plan Generated with config: \(generatedConfig)")
            }
        }
        .modelContainer(container)
        .environmentObject(ProfileViewModel())
    }
}
