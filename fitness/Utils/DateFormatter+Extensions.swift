
import Foundation

//extension Array where Element == WeightRecord {
//    func sortedByDateDesc() -> [WeightRecord] {
//        sorted { $0.date > $1.date }
//    }
//}

extension Date {
    var yyyyMMddHHmm: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: self)
    }
}
