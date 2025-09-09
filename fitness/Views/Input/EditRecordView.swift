import SwiftUI

struct EditRecordView: View {
    @EnvironmentObject var weightManager: WeightManager
    var record: WeightRecord

    @State private var weightText: String = ""
    @State private var date: Date = Date()

    var body: some View {
        Form {
            Section("Edit") {
                TextField("Weight", text: $weightText).keyboardType(.decimalPad)
                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
            }
            Section {
                Button("Save Changes") {
                    let normalized = weightText.replacingOccurrences(of: ",", with: ".")
                    if let value = Double(normalized) {
                        weightManager.update(record, weight: value, date: date)
                    }
                }
            }
        }
        .navigationTitle("Edit")
        .onAppear {
            weightText = String(format: "%.1f", record.weight)
            date = record.date
        }
    }
}
