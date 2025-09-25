import SwiftUI

struct FitnessProfileDetailView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel

    var body: some View {
        List {
            Section(header: Text("完善你的计划"), footer: Text("提供更多信息，可以让我们为你生成更精准、更有效的训练计划。")) {
                NavigationLink(destination: TrainingPreferenceView(profile: $profileViewModel.userProfile)) {
                    VStack(alignment: .leading) {
                        Text("训练偏好")
                            .font(.headline)
                        Text("你喜欢的运动方式和期望的训练频率")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                NavigationLink(destination: EquipmentListView(profile: $profileViewModel.userProfile)) {
                    VStack(alignment: .leading) {
                        Text("我的设备")
                            .font(.headline)
                        Text("你拥有的或方便使用的健身设备")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                NavigationLink(destination: MotivationView(profile: $profileViewModel.userProfile)) {
                    VStack(alignment: .leading) {
                        Text("动机与挑战")
                            .font(.headline)
                        Text("你的内在驱动力和可能遇到的障碍")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                NavigationLink(destination: NutritionView(profile: $profileViewModel.userProfile)) {
                    VStack(alignment: .leading) {
                        Text("饮食与营养")
                            .font(.headline)
                        Text("你的饮食习惯和饮水情况")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                NavigationLink(destination: BodyDataView(profile: $profileViewModel.userProfile)) {
                    VStack(alignment: .leading) {
                        Text("身体数据")
                            .font(.headline)
                        Text("你的睡眠质量和体能基准")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("健身档案")
        .listStyle(InsetGroupedListStyle())
        .onDisappear {
            // Save any changes when leaving this screen
            profileViewModel.saveProfile()
        }
    }
}

struct FitnessProfileDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FitnessProfileDetailView()
                .environmentObject(ProfileViewModel())
        }
    }
}
