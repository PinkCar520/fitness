import SwiftUI

struct WorkoutSetRowView: View {
    @Binding var set: WorkoutSet
    let setIndex: Int
    let onToggleCompletion: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text("第 \(setIndex + 1) 组")
                .fontWeight(.medium)
                .frame(width: 60)

            VStack {
                Text("次数")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Reps", value: $set.reps, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
            }

            VStack {
                Text("重量 (kg)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Weight", value: $set.weight, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Haptics.simpleSuccess()
                onToggleCompletion()
            }) {
                Image(systemName: (set.isCompleted ?? false) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor((set.isCompleted ?? false) ? .green : .gray)
            }
        }
        .padding(.vertical, 8)
    }
}

struct WorkoutSetRowView_Previews: PreviewProvider {
    @State static var previewSet = WorkoutSet(reps: 10, weight: 50)
    
    static var previews: some View {
        WorkoutSetRowView(set: $previewSet, setIndex: 0, onToggleCompletion: {})
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
