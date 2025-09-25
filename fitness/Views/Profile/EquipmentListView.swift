import SwiftUI

struct EquipmentListView: View {
    @Binding var profile: UserProfile

    var body: some View {
        Form {
            Section(header: Text("你拥有的设备"), footer: Text("我们会根据你的设备，解锁更多专属训练动作。")) {
                ForEach(Equipment.allCases) { equipment in
                    EquipmentToggleRow(equipment: equipment, selectedEquipment: Binding(
                        get: { profile.equipment ?? [] },
                        set: { profile.equipment = $0 }
                    ))
                }
            }
        }
        .navigationTitle("我的设备")
    }
}

struct EquipmentToggleRow: View {
    let equipment: Equipment
    @Binding var selectedEquipment: [Equipment]

    private var isSelected: Bool {
        selectedEquipment.contains(equipment)
    }

    var body: some View {
        Button(action: {
            withAnimation {
                if isSelected {
                    selectedEquipment.removeAll { $0 == equipment }
                } else {
                    selectedEquipment.append(equipment)
                }
            }
        }) {
            HStack {
                Text(equipment.rawValue)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

struct EquipmentListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EquipmentListView(profile: .constant(UserProfile()))
        }
    }
}
