import SwiftUI

// A generic multi-select row to be reused across different setting views
struct MultiSelectRow<T: RawRepresentable & Hashable & CaseIterable & Identifiable>: View where T.RawValue == String, T.ID == T {
    let item: T
    @Binding var selectedItems: [T]

    private var isSelected: Bool {
        selectedItems.contains(item)
    }

    var body: some View {
        Button(action: {
            withAnimation {
                if isSelected {
                    selectedItems.removeAll { $0 == item }
                } else {
                    selectedItems.append(item)
                }
            }
        }) {
            HStack {
                Text(item.rawValue)
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
