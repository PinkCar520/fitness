import SwiftUI

struct BodyDataView: View {
    @Binding var profile: UserProfile

    // Ensure bodyType is not nil for bindings
    private var bodyTypeBinding: Binding<BodyTypeSelection> {
        Binding(get: { profile.bodyType ?? BodyTypeSelection() }, set: { profile.bodyType = $0 })
    }

    var body: some View {
        Form {
            Section(header: Text("体型选择"), footer: Text("选择与你最接近的当前体型和期望达到的目标体型。")) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("当前体型")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    BodyTypeScrollView(selectedBodyType: bodyTypeBinding.current)
                    
                    Divider().padding(.vertical, 8)
                    
                    Text("目标体型")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    BodyTypeScrollView(selectedBodyType: bodyTypeBinding.goal)
                }
                .padding(.vertical, 8)
            }

            Section(header: Text("恢复与睡眠")) {
                Picker("睡眠质量", selection: Binding(
                    get: { profile.sleepQuality ?? .good },
                    set: { profile.sleepQuality = $0 }
                )) {
                    ForEach(SleepQuality.allCases) { quality in
                        Text(quality.rawValue).tag(quality)
                    }
                }
            }

            Section(header: Text("体能基准"), footer: Text("记录你的体能数据，见证自己的成长。")) {
                HStack {
                    Text("俯卧撑个数")
                    Spacer()
                    TextField("个数", value: Binding(
                        get: { profile.benchmarks?.pushups ?? 0 },
                        set: { 
                            if profile.benchmarks == nil {
                                profile.benchmarks = Benchmark()
                            }
                            profile.benchmarks?.pushups = $0 
                        }
                    ), format: .number)
                    .keyboardType(.numberPad)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
                }
            }
        }
        .navigationTitle("身体数据")
    }
}

struct BodyTypeScrollView: View {
    @Binding var selectedBodyType: BodyType?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(BodyType.allCases) {
                    type in
                    BodyTypeCard(type: type, selectedType: $selectedBodyType)
                }
            }
            .padding(.horizontal)
        }
        .padding(.horizontal, -20) // Offset ScrollView padding to align with Form
    }
}

struct BodyTypeCard: View {
    let type: BodyType
    @Binding var selectedType: BodyType?

    private var isSelected: Bool {
        type == selectedType
    }

    var body: some View {
        VStack {
            Image(systemName: icon(for: type))
                .font(.largeTitle)
                .frame(width: 60, height: 80)
                .foregroundColor(isSelected ? .accentColor : .secondary)
            Text(type.rawValue)
                .font(.caption)
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1.5)
        )
        .onTapGesture {
            withAnimation {
                selectedType = type
            }
        }
    }

    private func icon(for type: BodyType) -> String {
        switch type {
        case .slim: return "figure.walk"
        case .toned: return "figure.run"
        case .muscular: return "figure.strengthtraining.traditional"
        case .heavy: return "figure.cooldown"
        }
    }
}

struct BodyDataView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BodyDataView(profile: .constant(UserProfile()))
        }
    }
}
