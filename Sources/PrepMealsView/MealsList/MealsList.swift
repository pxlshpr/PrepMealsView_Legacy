import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftSugar

public struct MealsList: View {
    
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
    
    public var body: some View {
        if meals.isEmpty {
            emptyContent
        } else {
            list
        }
    }
}
