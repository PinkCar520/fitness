import SwiftUI

struct ProfilePopupView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var editingProfile: UserProfile

    init() {
        _editingProfile = State(initialValue: ProfileViewModel().userProfile)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) { // Overall spacing between sections
                    // MARK: - Profile Picture
                    VStack {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                            .clipShape(Circle())
                        Text("点击更换头像")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 10)

                    // MARK: - Basic Information
                    VStack(alignment: .leading, spacing: 15) { // Spacing within section
                        Text("基本信息")
                            .font(.headline)
                            .foregroundColor(.primary) // Ensure good contrast
                            .padding(.leading, 5) // Align with content

                        VStack(spacing: 10) { // Spacing between input rows
                            HStack {
                                Text("昵称")
                                Spacer() // Push TextField to the right
                                TextField("您的昵称", text: $editingProfile.name)
                                    .multilineTextAlignment(.trailing) // Align text to right
                                    .flymeInputStyle() // Apply custom style
                            }
                            
                            HStack {
                                Text("性别")
                                Spacer() // Push Picker to the right
                                Picker("性别", selection: $editingProfile.gender) {
                                    ForEach(Gender.allCases) { gender in
                                        Text(gender.rawValue).tag(gender)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 200) // Constrain width for segmented picker
                            }
                            .flymeInputStyle() // Apply custom style to HStack for background

                            HStack {
                                Text("出生日期")
                                Spacer() // Push DatePicker to the right
                                DatePicker("", selection: $editingProfile.dateOfBirth, displayedComponents: .date)                                    .labelsHidden() // Hide default picker label
                                    .datePickerStyle(.compact) // Use compact for cleaner look
                            }
                            .flymeInputStyle() // Apply custom style to HStack for background
                        }
                    }
                    .padding(.horizontal) // Padding for the whole section

                    // MARK: - Health & Goals
                    VStack(alignment: .leading, spacing: 15) {
                        Text("健康与目标")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.leading, 5)

                        VStack(spacing: 10) {
                            HStack {
                                Text("身高")
                                Spacer()
                                TextField("您的身高", value: $editingProfile.height, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .flymeInputStyle()
                                Picker("单位", selection: $editingProfile.heightUnit) {
                                    ForEach(HeightUnit.allCases) { unit in
                                        Text(unit.rawValue).tag(unit)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 100) // Constrain width
                            }
                            
                            HStack {
                                Text("目标体重")
                                Spacer()
                                TextField("您的目标体重", value: $editingProfile.targetWeight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .flymeInputStyle()
                                Picker("单位", selection: $editingProfile.weightUnit) {
                                    ForEach(WeightUnit.allCases) { unit in
                                        Text(unit.rawValue).tag(unit)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 100) // Constrain width
                            }
                            
                            HStack {
                                Text("活动水平")
                                Spacer()
                                Picker("活动水平", selection: $editingProfile.activityLevel) {
                                    ForEach(ActivityLevel.allCases) { level in
                                        Text(level.rawValue).tag(level)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden() // Hide default picker label
                            }
                            .flymeInputStyle() // Apply custom style to HStack for background
                        }
                    }
                    .padding(.horizontal) // Padding for the whole section

                }
                .padding(.horizontal, 24) // Increased horizontal padding for the whole content
                .padding(.vertical) // Keep vertical padding
            }
            .navigationTitle("个人资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill") // Changed to filled circle
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        profileViewModel.userProfile = editingProfile
                        profileViewModel.saveProfile()
                        dismiss()
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .onAppear {
            editingProfile = profileViewModel.userProfile
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
    }
}

// Custom Input Field Style
struct FlymeInputBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
    }
}

extension View {
    func flymeInputStyle() -> some View {
        self.modifier(FlymeInputBackground())
    }
}
