import Foundation

extension ListPage {
 
    var isToday: Bool {
        date.startOfDay == Date().startOfDay
    }
    
    var isBeforeToday: Bool {
        date.startOfDay < Date().startOfDay
    }
    
    var emptyText: String {
        isBeforeToday
        ? "No meals had been logged on this day"
        : "You haven't prepped any meals yet"
    }

    var mealTimeSuggestions: [Date] {
        meals.map({Date(timeIntervalSince1970: $0.time)})
            .suggestedMealTimes(includingSuggestionsRelativeToNow: isToday, forDate: date)
    }
}
