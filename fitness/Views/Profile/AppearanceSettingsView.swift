import SwiftUI

struct AppearanceSettingsView: View {
    @StateObject private var viewModel = AppearanceViewModel()

    var body: some View {
        Form {
            // Section for Theme Mode
            Section(header: Text("主题模式")) {
                Picker("选择模式", selection: $viewModel.theme) {
                    ForEach(Theme.allCases) { theme in
                        Text(theme.name).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Section for Accent Color
            Section(header: Text("主题颜色")) {
                HStack(spacing: 20) {
                    ForEach(AccentColor.allCases) { accentColor in
                        Circle()
                            .fill(accentColor.color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.caption)
                                    .opacity(viewModel.accentColor == accentColor ? 1.0 : 0.0)
                            )
                            .onTapGesture {
                                viewModel.accentColor = accentColor
                            }
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .navigationTitle("外观设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppearanceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AppearanceSettingsView()
        }
    }
}
