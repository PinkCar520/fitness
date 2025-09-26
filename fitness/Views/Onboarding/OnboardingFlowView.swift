import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var weightManager: WeightManager
    @Binding var showOnboarding: Bool
    
    @State private var onboardingData: UserProfile
    @State private var selection = 0

    // States for network simulation
    @State private var isGeneratingPlan = false
    @State private var showNetworkErrorAlert = false

    // UserDefaults keys for saving progress
    private let onboardingDataKey = "onboardingInProgressData"
    private let onboardingStepKey = "onboardingInProgressStep"

    init(showOnboarding: Binding<Bool>) {
        _showOnboarding = showOnboarding

        // Try to load saved progress
        if let savedData = UserDefaults.standard.data(forKey: onboardingDataKey), 
           let decodedData = try? JSONDecoder().decode(UserProfile.self, from: savedData) {
            _onboardingData = State(initialValue: decodedData)
            _selection = State(initialValue: UserDefaults.standard.integer(forKey: onboardingStepKey))
        } else {
            // Start fresh
            _onboardingData = State(initialValue: UserProfile(hasCompletedOnboarding: false))
            _selection = State(initialValue: 0)
        }
    }
    
    @ViewBuilder
    private var feedbackTextView: some View {
        let text: String? = {
            switch selection {
            case 1:
                guard let goal = onboardingData.goal else { return "请选择您的主要健身目标。" }
                return "目标已设定：\(goal.rawValue)。我们将为您优先推荐相关的训练。"
            case 2:
                guard let level = onboardingData.experienceLevel else { return "请告诉我们您的健身经验。" }
                return "好的，您的经验水平是'\(level.rawValue)'。我们将据此调整计划难度。"
            case 3:
                guard let location = onboardingData.workoutLocation else { return "请选择您的主要锻炼地点。" }
                return "收到！所有计划都将是您在'\(location.rawValue)'就能完成的动作。"
            case 4:
                guard let conditions = onboardingData.healthConditions else { return "请确认您的身体状况。" }
                if conditions.isEmpty {
                    return "太棒了，身体状况良好！"
                }
                let conditionNames = conditions.map { $0.rawValue }.joined(separator: "、")
                return "感谢告知。我们会特别注意保护您的'\(conditionNames)'。"
            default:
                return nil
            }
        }()

        if let text = text {
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(height: 40, alignment: .top)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    var body: some View {
        VStack {
            if selection > 0 && selection < 5 {
                ProgressView(value: Double(selection), total: 4)
                    .padding()
            }

            if selection > 0 && selection < 5 {
                feedbackTextView
                    .padding(.bottom)
            }

            TabView(selection: $selection) {
                WelcomeView().tag(0)
                GoalSelectionView(goal: $onboardingData.goal).tag(1)
                ExperienceLevelView(experienceLevel: $onboardingData.experienceLevel).tag(2)
                WorkoutLocationView(workoutLocation: $onboardingData.workoutLocation).tag(3)
                SafetyCheckView(healthConditions: $onboardingData.healthConditions).tag(4)
                CompletionView().tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .overlay(alignment: .bottom) {
                navigationButtons
            }
        }
        .onChange(of: onboardingData) { saveProgress() }
        .onChange(of: selection) { saveProgress() }
        .alert("生成计划失败", isPresented: $showNetworkErrorAlert) {
            Button("重试") { handleCompletion() }
            Button("取消", role: .cancel) { }
        } message: {
            Text("请检查您的网络连接并重试。 নিতে")
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            if selection < 5 {
                Button("上一步") {
                    withAnimation { selection -= 1 }
                }
                .padding()
                .opacity(selection > 0 ? 1.0 : 0.0)
            }

            Spacer()
            
            if isGeneratingPlan {
                ProgressView()
            } else if selection < 5 {
                Button(buttonText) {
                    handleNavigation()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("完成") {
                    withAnimation {
                        showOnboarding = false
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private var buttonText: String {
        switch selection {
        case 0:
            return "开始"
        case 4:
            return "完成并生成计划"
        default:
            return "下一步"
        }
    }

    private func handleNavigation() {
        if selection == 4 {
            handleCompletion()
        } else {
            withAnimation { selection += 1 }
        }
    }

    private func handleCompletion() {
        isGeneratingPlan = true
        // Simulate network call with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Simulate a random failure
            if Bool.random() { // Success
                onboardingData.hasCompletedOnboarding = true
                profileViewModel.userProfile = onboardingData
                profileViewModel.saveProfile()
                healthKitManager.setupHealthKitData(weightManager: weightManager)
                clearSavedProgress()
                withAnimation { selection = 5 }
            } else { // Failure
                showNetworkErrorAlert = true
            }
            isGeneratingPlan = false
        }
    }

    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(onboardingData) {
            UserDefaults.standard.set(encoded, forKey: onboardingDataKey)
            UserDefaults.standard.set(selection, forKey: onboardingStepKey)
        }
    }

    private func clearSavedProgress() {
        UserDefaults.standard.removeObject(forKey: onboardingDataKey)
        UserDefaults.standard.removeObject(forKey: onboardingStepKey)
    }
}

struct OnboardingFlowView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: HealthMetric.self, configurations: config)
        let healthKitManager = HealthKitManager()
        let weightManager = WeightManager(healthKitManager: healthKitManager, modelContainer: container)

        OnboardingFlowView(showOnboarding: .constant(true))
            .environmentObject(ProfileViewModel())
            .environmentObject(healthKitManager)
            .environmentObject(weightManager)
    }
}