import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes
import SwiftSugar

public struct ListPage: View {
    
    let didAddMeal = NotificationCenter.default.publisher(for: .didAddMeal)
    let didUpdateMeals = NotificationCenter.default.publisher(for: .didUpdateMeals)
    let onTapAddMeal: ((Date?) -> ())

    let date: Date
    @Binding var meals: [DayMeal]

    public init(
        date: Date,
        meals: Binding<[DayMeal]>,
        onTapAddMeal: @escaping ((Date?) -> ())
    ) {
        self.date = date
        _meals = meals
        self.onTapAddMeal = onTapAddMeal
    }
    
    var isToday: Bool {
        date.startOfDay == Date().startOfDay
    }
    
    var isBeforeToday: Bool {
        date.startOfDay < Date().startOfDay
    }
    
    public var body: some View {
        if meals.isEmpty {
            emptyContent
        } else {
            list
        }
    }
    
    var list: some View {
        List {
            ForEach(meals) { meal in
                MealView(meal: meal)
            }
            addMealButtons
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }
    
    var emptyText: String {
        isBeforeToday
        ? "No meals had been logged on this day"
        : "You haven't prepped any meals yet"
    }
    var emptyContent: some View {
        ZStack {
            Color(.systemGroupedBackground)
            VStack {
                Text(emptyText)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(.tertiaryLabel))
                addMealEmptyButton
            }
            .padding()
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .foregroundColor(Color(.quaternarySystemFill))
            )
            .padding(.horizontal, 50)
        }
    }
    
//    func didAddMeal(notification: Notification) {
//        guard let userInfo = notification.userInfo,
//              let meal = userInfo[Notification.Keys.meal] as? Meal,
//              meal.day.calendarDayString == self.date.calendarDayString
//        else {
//            return
//        }
//        getMeals()
//    }
//    
//    func didUpdateMeals(notification: Notification) {
//        getMeals()
//    }
//
//    func appeared() {
//        getMeals(animated: false)
//    }
    
    var addMealEmptyButton: some View {
        let string = isBeforeToday ? "Log a Meal" : "Prep a Meal"
        return Button {
            onTapAddMeal(nil)
        } label: {
            HStack {
                Image(systemName: "note.text.badge.plus")
                Text(string)
            }
            .foregroundColor(.white)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
//                Capsule(style: .continuous)
                    .foregroundColor(Color.accentColor)
            )
        }
        .buttonStyle(.borderless)
    }

    var addMealButton: some View {
        Button {
            onTapAddMeal(nil)
            Haptics.feedback(style: .soft)
        } label: {
            HStack {
                Image(systemName: "note.text.badge.plus")
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .foregroundColor(Color(.tertiarySystemFill))
            )
        }
        .buttonStyle(.borderless)
    }
    
    func addMealAtTimeButton(at time: Date? = nil) -> some View {
        Button {
            onTapAddMeal(time ?? Date())
            Haptics.successFeedback()
        } label: {
            HStack {
                if let time {
                    Text(time.hourString)
                } else {
                    Text("Now")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .foregroundColor(Color(.tertiarySystemFill))
            )
        }
        .buttonStyle(.borderless)
    }
    
    var mealTimeSuggestions: [Date] {
        meals.map({Date(timeIntervalSince1970: $0.time)})
            .suggestedMealTimes(includingSuggestionsRelativeToNow: isToday)
    }
    
    var addMealButtons: some View {
        Section {
            HStack(spacing: 15) {
                addMealButton
                if isToday {
                    addMealAtTimeButton()
                }
                ForEach(mealTimeSuggestions.indices, id: \.self) {
                    addMealAtTimeButton(at: mealTimeSuggestions[$0])
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 15)
        .listRowBackground(
            ZStack {
                ListRowBackground(
                    color: Color(.systemGroupedBackground),
                    includeTopSeparator: false,
                    includeBottomSeparator: false,
                    includeTopPadding: true
                )
            }
        )
        .listRowSeparator(.hidden)
    }
}

struct AddMealButtonItem {
    let isQuickAdd: Bool
    let time: Date?
    init(isQuickAdd: Bool = true, time: Date? = nil) {
        self.isQuickAdd = isQuickAdd
        self.time = time
    }
}
struct EmptyListViewPreview: View {
    
    @Namespace var namespace
    
    var body: some View {
        ListPage(
            date: Date(),
            meals: .constant([]),
            onTapAddMeal: { _ in }
        )
    }
}

struct EmptyViewPreview: PreviewProvider {
    
    static var previews: some View {
        EmptyListViewPreview()
    }
}

import SwiftUI

struct ListRowBackground: View {
    
    @Environment(\.colorScheme) var colorScheme
    @State var color: Color = .clear
    @State var separatorColor: Color? = nil
    @State var includeTopSeparator: Bool = false
    @State var includeBottomSeparator: Bool = false
    @State var includeTopPadding: Bool = false
    
    var body: some View {
        ZStack {
            color
            VStack(spacing: 0) {
                if includeTopPadding {
                    Color.clear.frame(height: 10)
                }
                if includeTopSeparator {
                    separator
                        .if(separatorColor != nil) { view in
                            view.foregroundColor(separatorColor!)
                        }
                }
                Spacer()
                if includeBottomSeparator {
                    separator
                }
            }
        }
    }
    
    var separator: some View {
        Rectangle()
            .frame(height: 0.18)
            .background(Color(.separator))
            .opacity(colorScheme == .light ? 0.225 : 0.225)
    }
}

//MARK: - Prep Specific

extension Array where Element == Date {
    func suggestedMealTimes(includingSuggestionsRelativeToNow: Bool = false) -> [Date] {
        
        func newDateIfOnSameDay(_ hours: Int, hoursAfter date: Date) -> Date? {
            guard hours > 0 else { return nil }
            let newDate = date.atClosestHour.movingHourBy(hours)
            
            /// If the `newDate` is on the next day, only return it if it's before 6am
            if newDate.day > date.day  {
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
            //TODO: Check that these are within the wee hours of the next day
            if abs(last.timeIntervalSince1970 - Date().timeIntervalSince1970) < 3600 {
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








struct ListPagerPreview: View {
    @Namespace var namespace
    
    var body: some View {
        NavigationView {
            listPage
                .navigationTitle("List Page")
        }
    }
    
    var listPage: some View {
        ListPage(
            date: Date(),
            meals: .constant(meals.map { DayMeal(from: $0) })
        ) { _ in
            /// Tapped Add meal
        }
    }
    
    var meals: [Meal] {
        [
            mockMeal("Breakfast", at: Date().h(8, r: true)),
            mockMeal("Lunch", at: Date().h(12, r: true)),
            mockMeal("Pre-workout Meal", at: Date().h(14, r: true))
        ]
    }
    
    func mockMeal(_ name: String, at time: Date) -> Meal {
        Meal(id: UUID(), day: day,
             name: name,
             time: time.timeIntervalSince1970,
             markedAsEatenAt: 0,
             foodItems: [],
             syncStatus: .notSynced, updatedAt: 0)
    }
    
    var day: Day {
        Day(id: "day", calendarDayString: "", addEnergyExpendituresToGoal: false, energyExpenditures: [], meals: [], syncStatus: .notSynced, updatedAt: 0)
    }
}

struct ListPager_Previews: PreviewProvider {
    static var previews: some View {
        ListPagerPreview()
    }
}

extension DayMeal {
    init(from meal: Meal) {
        self.init(
            id: meal.id,
            name: meal.name,
            time: meal.time,
            foodItems: meal.foodItems
        )
    }
}
