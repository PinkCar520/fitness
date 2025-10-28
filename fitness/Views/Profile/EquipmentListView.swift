import SwiftUI

struct EquipmentListView: View {
    @Binding var profile: UserProfile

    var body: some View {
        Form {
            Section(header: Text("你拥有的设备"), footer: Text("我们会根据你的设备，解锁更多专属训练动作。")) {
                ForEach(EquipmentType.allCases) { equipmentType in // Changed to EquipmentType.allCases
                    EquipmentToggleRow(equipmentType: equipmentType, selectedEquipment: Binding(
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
    let equipmentType: EquipmentType // Changed to EquipmentType
    @Binding var selectedEquipment: [EquipmentType] // Changed to EquipmentType

    private var isSelected: Bool {
        selectedEquipment.contains(equipmentType)
    }

    var body: some View {
        Button(action: {
            withAnimation {
                if isSelected {
                    selectedEquipment.removeAll { $0 == equipmentType }
                } else {
                    selectedEquipment.append(equipmentType)
                }
            }
        }) {
            HStack {
                Text(equipmentType.rawValue) // Changed to equipmentType.rawValue
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
            // Provide a mock UserProfile with EquipmentType
            @State var mockProfile = UserProfile()
            mockProfile.equipment = [.dumbbells, .yogaMat] // Example with EquipmentType
            
            return EquipmentListView(profile: $mockProfile)
        }
    }
}
