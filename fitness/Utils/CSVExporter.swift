import Foundation
import SwiftData

enum CSVExporter {
    static func makeCSV(from records: [HealthMetric]) -> String {
        var lines = ["date,weight"]
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        for r in records.sorted(by: { $0.date < $1.date }) {
            let date = iso.string(from: r.date)
            let w = String(format: "%.1f", r.value)
            lines.append("\(date),\(w)")
        }
        return lines.joined(separator: "\n")
    }

    static func makeCSVURL(from records: [HealthMetric]) -> URL {
        let csv = makeCSV(from: records)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("weights.csv")
        try? csv.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }
}

