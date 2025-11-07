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
}

// MARK: - Main View

struct PlanSetupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Query(filter: #Predicate<Plan> { $0.status == "active" }, sort: \.startDate, order: .reverse)
    private var activePlans: [Plan]
    
    @State private var config = PlanConfiguration()
    @State private var currentStep = 0
    @State private var isLoadingPlan = false // NEW STATE VARIABLE
    @State private var loadingStartTime: Date?
    @State private var hasSeededExistingPlan = false
    
    var onComplete: @Sendable (PlanConfiguration) async -> Void

    private let totalSteps = 9

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
                    ExperienceLevelStepView(experienceLevel: $config.experienceLevel, currentStep: $currentStep).tag(1)
                    TargetWeightStepView(targetWeight: $config.targetWeight, currentStep: $currentStep).tag(2)
                    DurationStepView(duration: $config.workoutDurationPerSession, currentStep: $currentStep).tag(3)
                    LifestyleStepView(sleepTarget: $config.sleepDurationTarget).tag(4)
                    CycleStepView(planDuration: $config.planDuration).tag(5)
                    ScheduleStepView(frequency: $config.workoutFrequency, selectedDays: $config.trainingDays).tag(6)
                    ConfirmationStepView(
                        config: config,
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
    @Binding var currentStep: Int
    private let sliderConfiguration = TargetWeightSliderConfiguration.planSetup

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            AnimatedRunningIcon()
            Spacer().frame(height: 30)
            Text("您的目标体重是？").font(.largeTitle).bold().multilineTextAlignment(.center)
            
            TargetWeightSlider(
                weight: $targetWeight,
                baselineWeight: targetWeight,
                configuration: sliderConfiguration
            )
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
            .cornerRadius(32)

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
                            ConfirmationCard(iconName: "calendar.badge.clock", label: "计划周期", value: "\(config.planDuration) 天")
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
