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
    
    private var buttonText: String {
        switch selection {
        case 0:
            return "开始"
        case 4:
            return "完成并生成计划"
        case 5: // Completion view
            return "完成"
        default:
            return "下一步"
        }
    }

    private func handleNavigation() {
        if selection == 0 {
            healthKitManager.requestAuthorization { _ in
                // Always proceed to the next step, regardless of authorization status
                DispatchQueue.main.async {
                    withAnimation { selection += 1 }
                }
            }
        } else if selection == 4 {
            handleCompletion()
        } else if selection == 5 {
            withAnimation {
                showOnboarding = false
            }
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
                                Task {
                    await healthKitManager.setupHealthKitData(weightManager: weightManager)
                }
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

    var body: some View {
        VStack {
            Group {
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
                    VStack {
                        if selection == 0 { // Only show privacy text on WelcomeView
                            VStack(spacing: 5) {
                                Text("点击“开始”即表示您同意我们的")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 5) {
                                    Link("服务条款", destination: URL(string: "https://www.example.com/terms")!)
                                        .font(.caption)
                                    Text("和")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Link("隐私政策", destination: URL(string: "https://www.example.com/privacy")!)
                                        .font(.caption)
                                    Text("且授权")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Button(action: { openUrl(urlString: "x-apple-health://") }) {
                                        Text("Apple健康")
                                            .font(.caption)
                                    }
                                    Text("数据")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.bottom, 10)
                        }

                        if selection > 0 && selection < 5 { // ProgressView moved to bottom
                            ProgressView(value: Double(selection), total: 4)
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                        }
                        if isGeneratingPlan {
                            ProgressView()
                                .padding(.bottom, 20)
                        } else {
                            Button(buttonText) {
                                handleNavigation()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .frame(maxWidth: .infinity) // Text buttons fill width
                            .padding(.horizontal)
                            .padding(.bottom, 10)

                        }
                    }
                }
            }
            .onChange(of: onboardingData) { saveProgress() }
            .onChange(of: selection) { saveProgress() }
            .alert("生成计划失败", isPresented: $showNetworkErrorAlert) {
                Button("重试") { handleCompletion() }
                Button("取消", role: .cancel) { }
            } message: {
                Text("请检查您的网络连接并重试。")
            }
        }
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
