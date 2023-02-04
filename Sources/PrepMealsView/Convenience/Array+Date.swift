import Foundation

extension Array where Element == Date {
    func suggestedMealTimes(includingSuggestionsRelativeToNow: Bool = false, forDate dayDate: Date) -> [Date] {
        
        func newDateIfOnSameDay(_ hours: Int, hoursAfter date: Date) -> Date? {
            guard hours > 0 else { return nil }
            let newDate = date.atClosestHour.movingHourBy(hours)
            
            /// If the `newDate` is on the next day, only return it if it's before 6am
            if !Calendar.autoupdatingCurrent.isDate(newDate, inSameDayAs: dayDate) {
                guard newDate.h < 6 else { return nil }
            }
            return newDate
        }

        func timesTillEndOfDay(from start: Date, increment: Int = 2) -> [Date] {
            var times: [Date] = []
            var hours: Int = increment
            while hours < 24 {
                guard let time = newDateIfOnSameDay(hours, hoursAfter: start) else {
                    break
                }
                times.append(time)
                hours += increment
            }
            return times
        }
        
        let sorted = self.sorted(by: { $0 < $1})
        guard let last = sorted.last else { return [] }

        let twoHoursFromLast = newDateIfOnSameDay(2, hoursAfter: last)

        let suggestions: [Date?]
        if includingSuggestionsRelativeToNow {
            let times = timesTillEndOfDay(from: Date())
            
            /// if the last meal is within 1 hour from now (in either direction)
            if abs(last.timeIntervalSince1970 - Date().timeIntervalSince1970) < 3600
                || twoHoursFromLast == nil
            {
                suggestions = times
            } else {
                suggestions = [twoHoursFromLast] + times
            }
        } else {
            let times = timesTillEndOfDay(from: last)
            suggestions = times
        }
        
        return suggestions.compactMap { $0 }
    }
}
