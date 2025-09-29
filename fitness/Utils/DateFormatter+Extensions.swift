import Foundation

extension DateFormatter {
    static let yyyyMMddHHmm: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    static let MMddHHmm: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }()
}

extension Date {
    var yyyyMMddHHmm: String {
        DateFormatter.yyyyMMddHHmm.string(from: self)
    }
    var shortDate: String {
        DateFormatter.shortDate.string(from: self)
    }
    var MMddHHmm: String {
        DateFormatter.MMddHHmm.string(from: self)
    }

    func startOfWeek(using calendar: Calendar = .current) -> Date {
        var customCalendar = calendar
        customCalendar.firstWeekday = 2 // Monday
        return customCalendar.date(from: customCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
    }
}
