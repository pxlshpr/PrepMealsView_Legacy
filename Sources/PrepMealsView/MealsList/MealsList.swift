import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftSugar

public struct MealsList: View {
    
    let didAddMeal = NotificationCenter.default.publisher(for: .didAddMeal)
    let didUpdateMeals = NotificationCenter.default.publisher(for: .didUpdateMeals)
    
    let onTapAddMeal: ((Date?) -> ())
    let didTapAddFood: ((DayMeal) -> ())

    let date: Date
    @Binding var meals: [DayMeal]

    public init(
        date: Date,
        meals: Binding<[DayMeal]>,
        didTapAddFood: @escaping (DayMeal) -> (),
        onTapAddMeal: @escaping ((Date?) -> ())
    ) {
        self.date = date
        _meals = meals
        self.onTapAddMeal = onTapAddMeal
        self.didTapAddFood = didTapAddFood
    }
    
    public var body: some View {
        if meals.isEmpty {
            emptyContent
        } else {
            list
        }
    }
}
