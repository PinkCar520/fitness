//
//import Foundation
//import Combine
//
//final class WeightStore: ObservableObject {
//    @Published var records: [WeightRecord] = [] {
//        didSet { persist() }
//    }
//    @Published var showAlert: Bool = false
//    @Published var alertMessage: String = ""
//    
//    private let filename = "weights.json"
//    private var fileURL: URL {
//        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        return dir.appendingPathComponent(filename)
//    }
//
//    init() {
//        load()
//        if records.isEmpty {
//            // Seed a week of sample data
//            let today = Date()
//            let cal = Calendar.current
//            self.records = (0..<7).map { i in
//                let d = cal.date(byAdding: .day, value: -i, to: today) ?? today
//                return WeightRecord(date: d, weight: 67.0 + Double.random(in: -0.8...0.8), note: i == 0 ? "Sample" : nil)
//            }.sorted { $0.date < $1.date }
//        }
//    }
//
////    func add(weight: Double, date: Date = Date(), note: String? = nil) {
////        var new = WeightRecord(date: date, weight: weight, note: note?.nilIfEmpty)
////        records.append(new)
////        records.sort { $0.date < $1.date }
////    }
//
//    func add(weight: Double, date: Date = Date(), note: String? = nil) -> Bool {
//        guard (30...200).contains(weight) else {
//            alertMessage = "⚠️ 体重 \(weight)kg 不在有效范围 30~200kg"
//            showAlert = true
//            return false
//        }
//        
//        let new = WeightRecord(
//            date: date,
//            weight: round(weight * 10) / 10,
//            note: note?.isEmpty == true ? nil : note
//        )
//        records.append(new)
//        records.sort { $0.date < $1.date }
//        return true
//    }
//    
////    func update(_ record: WeightRecord, weight: Double, date: Date, note: String?) {
////        guard let idx = records.firstIndex(where: { $0.id == record.id }) else { return }
////        records[idx].weight = weight
////        records[idx].date = date
////        records[idx].note = note?.nilIfEmpty
////        records.sort { $0.date < $1.date }
////    }
//
//    func update(_ record: WeightRecord, weight: Double, date: Date, note: String?) {
//        guard (30...200).contains(weight) else { return }
//        guard let idx = records.firstIndex(where: { $0.id == record.id }) else { return }
//        records[idx].weight = round(weight * 10) / 10
//        records[idx].date = date
//        records[idx].note = note?.nilIfEmpty
//        records.sort { $0.date < $1.date }
//    }
//    
//    
//    func delete(at offsets: IndexSet) {
//        let sorted = records.sortedByDateDesc()
//        var idsToDelete = offsets.map { sorted[$0].id }
//        records.removeAll { idsToDelete.contains($0.id) }
//    }
//
//    func clearAll() {
//        records.removeAll()
//    }
//
//    func averageWeight(days: Int = 7) -> Double? {
//        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
//        let recent = records.filter { $0.date >= cutoff }
//        guard !recent.isEmpty else { return nil }
//        let sum = recent.reduce(0) { $0 + $1.weight }
//        return sum / Double(recent.count)
//    }
//
//    private func load() {
//        do {
//            let data = try Data(contentsOf: fileURL)
//            let decoded = try JSONDecoder().decode([WeightRecord].self, from: data)
//            self.records = decoded
//        } catch {
//            self.records = []
//        }
//    }
//
//    private func persist() {
//        do {
//            let data = try JSONEncoder().encode(records)
//            try data.write(to: fileURL, options: [.atomic])
//        } catch {
//            print("Persist error: \(error)")
//        }
//    }
//}
//// MARK: - 便捷扩展
//extension WeightStore {
//    /// 最新一条体重记录
//    var latestRecord: WeightRecord? {
//        records.sorted { $0.date > $1.date }.first
//    }
//    
//    /// 本周变化（与一周前比较）
//    func weightChangeThisWeek() -> Double? {
//        guard let latest = latestRecord else { return nil }
//        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: latest.date)!
//        let weekAgoRecord = records
//            .filter { $0.date <= oneWeekAgo }
//            .sorted { $0.date > $1.date }
//            .first
//        if let weekAgo = weekAgoRecord {
//            return latest.weight - weekAgo.weight
//        }
//        return nil
//    }
//}
//
//private extension String {
//    var nilIfEmpty: String? { self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self }
//}
