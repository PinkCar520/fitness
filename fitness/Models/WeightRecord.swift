
import Foundation

/// 单条体重记录
struct WeightRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()         // 唯一 ID
    var date: Date = Date()       // 记录日期
    var weight: Double            // 体重值（kg）
}

// MARK: - Array 扩展
extension Array where Element == WeightRecord {
    /// 按日期倒序排序（最新在前）
    func sortedByDateDesc() -> [WeightRecord] {
        self.sorted { $0.date > $1.date }
    }
}

extension WeightRecord {
    var formattedWeight: String {
        String(format: "%.1fkg", weight)
    }
}
