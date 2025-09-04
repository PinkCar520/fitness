import SwiftUI

struct HistoryListView: View {
    @EnvironmentObject var weightManager: WeightManager
    @State private var recordToDelete: WeightRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History").font(.title3).bold()
            if weightManager.records.isEmpty {
                Text("No data yet. Add your first weight entry above.").foregroundStyle(.secondary)
            } else {
                ForEach(weightManager.records.sortedByDateDesc()) { rec in
                    NavigationLink { EditRecordView(record: rec) } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(rec.date.yyyyMMddHHmm).font(.headline)
                                if let note = rec.note, !note.isEmpty {
                                    Text(note).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(String(format: "%.1f kg", rec.weight)).font(.headline)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .contextMenu {
                        Button(role: .destructive) { recordToDelete = rec } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .alert("Delete Record?", isPresented: .init(get: { recordToDelete != nil }, set: { if !$0 { recordToDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let rec = recordToDelete { weightManager.delete(rec) }
                recordToDelete = nil
            }
            Button("Cancel", role: .cancel) { recordToDelete = nil }
        }
    }
}
