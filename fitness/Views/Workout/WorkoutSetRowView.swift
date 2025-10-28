import SwiftUI

struct WorkoutSetRowView: View {
    @Binding var set: WorkoutSet
    let setIndex: Int
    let onToggleCompletion: () -> Void

    @State private var showingRepsPicker = false
    @State private var showingWeightPicker = false

    var body: some View {
        HStack(spacing: 16) {
            Text("第 \(setIndex + 1) 组")
                .fontWeight(.medium)
                .frame(width: 60)

            VStack {
                Text("次数")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Button(action: {
                        if set.reps > 0 { set.reps -= 1 }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    Text("\(set.reps)")
                        .font(.title2)
                        .frame(minWidth: 40)
                        .onTapGesture { showingRepsPicker = true }
                    Button(action: {
                        set.reps += 1
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
            }

            VStack {
                Text("重量 (kg)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Button(action: {
                        if let currentWeight = set.weight, currentWeight > 0 {
                            set.weight = currentWeight - 2.5
                        } else if set.weight == nil {
                            set.weight = 0.0 // Start from 0 if nil
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    Text("\(set.weight ?? 0.0, specifier: "%.1f")") // Use nil coalescing for display
                        .font(.title2)
                        .frame(minWidth: 60)
                        .onTapGesture { showingWeightPicker = true }
                    Button(action: {
                        if let currentWeight = set.weight {
                            set.weight = currentWeight + 2.5
                        } else {
                            set.weight = 2.5 // Start from 2.5 if nil
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
            }

            Button(action: {
                onToggleCompletion()
            }) {
                Image(systemName: (set.isCompleted ?? false) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor((set.isCompleted ?? false) ? .green : .gray)
            }
        }
        .padding(.vertical, 8)
        .background(set.isCompleted ?? false ? Color.green.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .sheet(isPresented: $showingRepsPicker) {
            VStack {
                Text("选择次数")
                    .font(.headline)
                    .padding()
                Picker("次数", selection: $set.reps) {
                    ForEach(0..<101) { i in
                        Text("\(i)").tag(i)
                    }
                }
                .pickerStyle(.wheel)
                .presentationDetents([.medium, .large])
                Button("确定") { showingRepsPicker = false }
            }
        }
        .sheet(isPresented: $showingWeightPicker) {
            VStack {
                Text("选择重量 (kg)")
                    .font(.headline)
                    .padding()
                Picker("重量", selection: Binding(get: { set.weight ?? 0.0 }, set: { set.weight = $0 })) { // Handle optional weight for picker
                    ForEach(Array(stride(from: 0.0, through: 200.0, by: 2.5)), id: \.self) { weight in
                        Text("\(weight, specifier: "%.1f")").tag(weight)
                    }
                }
                .pickerStyle(.wheel)
                .presentationDetents([.medium, .large])
                Button("确定") { showingWeightPicker = false }
            }
        }
    }
}

struct WorkoutSetRowView_Previews: PreviewProvider {
    @State static var previewSet = WorkoutSet(reps: 10, weight: 50.0) // Make weight non-optional for preview
    
    static var previews: some View {
        WorkoutSetRowView(set: $previewSet, setIndex: 0, onToggleCompletion: {}) 
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

