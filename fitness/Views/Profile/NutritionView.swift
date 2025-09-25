import SwiftUI

struct NutritionView: View {
    @Binding var profile: UserProfile

    var body: some View {
        Form {
            Section(header: Text("你的日常饮食习惯？")) {
                ForEach(DietaryHabit.allCases) { habit in
                    MultiSelectRow(item: habit, selectedItems: Binding(
                        get: { profile.dietaryHabits ?? [] },
                        set: { profile.dietaryHabits = $0 }
                    ))
                }
            }

            Section(header: Text("每日饮水量大约是多少？")) {
                Picker("饮水量", selection: Binding(
                    get: { profile.waterIntake ?? .medium },
                    set: { profile.waterIntake = $0 }
                )) {
                    ForEach(WaterIntake.allCases) { intake in
                        Text(intake.rawValue).tag(intake)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .navigationTitle("饮食与营养")
    }
}

struct NutritionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NutritionView(profile: .constant(UserProfile()))
        }
    }
}
