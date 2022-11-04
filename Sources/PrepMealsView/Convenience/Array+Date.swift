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

        let sorted = self.sorted(by: { $0 < $1})
        guard let last = sorted.last else { return [] }

        let twoHoursFromLast = newDateIfOnSameDay(2, hoursAfter: last)

        let suggestions: [Date?]
        if includingSuggestionsRelativeToNow {
            
            /// if the last meal is within 1 hour from now (in either direction)
            let twoHoursFromNow = newDateIfOnSameDay(2, hoursAfter: Date())
            let fourHoursFromNow = newDateIfOnSameDay(4, hoursAfter: Date())
            
            if abs(last.timeIntervalSince1970 - Date().timeIntervalSince1970) < 3600
                || twoHoursFromLast == nil
            {
                suggestions = [twoHoursFromNow, fourHoursFromNow]
            } else {
                suggestions = [twoHoursFromLast, twoHoursFromNow]
            }
        } else {
            let fourHoursFromLast = newDateIfOnSameDay(4, hoursAfter: last)
            suggestions = [twoHoursFromLast, fourHoursFromLast]
        }
        return suggestions.compactMap { $0 }
    }
}
