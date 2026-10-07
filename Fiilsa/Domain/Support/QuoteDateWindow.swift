import Foundation

enum QuoteDateWindow {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }()

    static func endDate(containing date: String, anchor: String) -> String? {
        guard let selected = formatter.date(from: date),
              let today = formatter.date(from: anchor),
              let distance = calendar.dateComponents([.day], from: selected, to: today).day,
              distance >= 0,
              let end = calendar.date(byAdding: .day, value: -(distance / 7) * 7, to: today)
        else { return nil }
        return formatter.string(from: end)
    }
}
