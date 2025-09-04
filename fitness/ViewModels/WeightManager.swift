import Foundation
import Combine

final class WeightManager: ObservableObject {
    @Published var records: [WeightRecord] = []
    @Published var latestRecord: WeightRecord? = nil
    
    // Alert 信息供 UI 绑定
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    private let filename = "weights.json"
    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(filename)
    }

    init() {
        latestRecord = records.sorted { $0.date > $1.date }.first
        if records.isEmpty { seedSampleData() }
    }
    
    // MARK: - CRUD
    func add(weight: Double, date: Date = Date(), note: String? = nil) {
        guard (30...200).contains(weight) else {
            alertMessage = "⚠️ 体重 \(weight)kg 不在有效范围 30~200kg"
            showAlert = true
            return
        }
        let record = WeightRecord(date: date, weight: round(weight * 10)/10, note: note?.nilIfEmpty)
        records.append(record)
        records.sort { $0.date < $1.date }
        latestRecord = records.sorted { $0.date > $1.date }.first
        persistAndSync()
    }

    func update(_ record: WeightRecord, weight: Double, date: Date, note: String?) {
        guard let idx = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[idx].weight = round(weight * 10)/10
        records[idx].date = date
        records[idx].note = note?.nilIfEmpty
        records.sort { $0.date < $1.date }
        latestRecord = records.sorted { $0.date > $1.date }.first
        persistAndSync()
    }

    func delete(_ record: WeightRecord) {
        records.removeAll { $0.id == record.id }
        latestRecord = records.sorted { $0.date > $1.date }.first
        persistAndSync()
    }

    func clearAll() {
        records.removeAll()
        latestRecord = nil
        persistAndSync()
    }
    
    // MARK: - 派生数据
    func weightChangeThisWeek() -> Double? {
        guard let latest = latestRecord else { return nil }
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: latest.date)!
        let weekAgoRecord = records.filter { $0.date <= oneWeekAgo }.sorted { $0.date > $1.date }.first
        if let weekAgo = weekAgoRecord { return latest.weight - weekAgo.weight }
        return nil
    }

    func averageWeight(days: Int = 7) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recent = records.filter { $0.date >= cutoff }
        guard !recent.isEmpty else { return nil }
        return recent.reduce(0) { $0 + $1.weight } / Double(recent.count)
    }

    // MARK: - 持久化 & 云同步
    private func persistAndSync() {
        persist()
        syncToCloud()
    }
    
    private func persist() {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Persist error: \(error)")
        }
    }
    
    func syncToCloud() {
        // TODO: 接入 CloudKit/iCloud
        // 1. 上传本地 records
        // 2. 合并云端数据
        // 3. 处理冲突
    }
    
    private func seedSampleData() {
        let today = Date()
        let cal = Calendar.current
        self.records = (0..<7).map { i in
            let d = cal.date(byAdding: .day, value: -i, to: today) ?? today
            return WeightRecord(date: d, weight: 67.0 + Double.random(in: -0.8...0.8), note: i == 0 ? "Sample" : nil)
        }.sorted { $0.date < $1.date }
        latestRecord = records.last
    }
}

private extension String {
    var nilIfEmpty: String? { self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self }
}
