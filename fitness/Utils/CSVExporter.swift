import Foundation

enum CSVExporter {
    static func makeCSV(from records: [WeightRecord]) -> String {
        var lines = ["date,weight,note"]
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        for r in records.sorted(by: { $0.date < $1.date }) {
            let date = iso.string(from: r.date)
            let w = String(format: "%.1f", r.weight)
            let note = r.note?.replacingOccurrences(of: ",", with: ";") ?? ""
            lines.append("\(date),\(w),\(note)")
        }
        return lines.joined(separator: "\n")
    }

    static func makeCSVURL(from records: [WeightRecord]) -> URL {
        let csv = makeCSV(from: records)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("weights.csv")
        try? csv.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }
}

