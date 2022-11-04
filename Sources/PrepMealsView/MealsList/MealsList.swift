import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftSugar

public struct MealsList: View {
    
    let didAddMeal = NotificationCenter.default.publisher(for: .didAddMeal)
    let didUpdateMeals = NotificationCenter.default.publisher(for: .didUpdateMeals)
    let onTapAddMeal: ((Date?) -> ())
    let onTapMealMenu: ((DayMeal) -> ())
    
    let date: Date
    @Binding var meals: [DayMeal]

    public init(
        date: Date,
        meals: Binding<[DayMeal]>,
        onTapAddMeal: @escaping ((Date?) -> ()),
        onTapMealMenu: @escaping ((DayMeal) -> ())
    ) {
        self.date = date
        _meals = meals
        self.onTapAddMeal = onTapAddMeal
        self.onTapMealMenu = onTapMealMenu
    }
    
    public var body: some View {
        if meals.isEmpty {
            emptyContent
        } else {
            list
        }
    }
}
