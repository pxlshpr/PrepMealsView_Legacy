import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftSugar

public struct MealsList: View {
    
//    let didAddMeal = NotificationCenter.default.publisher(for: .didAddMeal)
//    let didDeleteMeal = NotificationCenter.default.publisher(for: .didDeleteMeal)
//    let didUpdateMeals = NotificationCenter.default.publisher(for: .didUpdateMeals)
    
    let onTapAddMeal: ((Date?) -> ())
    let didTapAddFood: ((DayMeal) -> ())
    let didTapEditMeal: ((DayMeal) -> ())
    let didTapMealFoodItem: ((MealFoodItem, DayMeal) -> ())

    let date: Date
    @Binding var meals: [DayMeal]

    @State var animation: Animation? = .none
    
    public init(
        date: Date,
        meals: Binding<[DayMeal]>,
        didTapAddFood: @escaping (DayMeal) -> (),
        didTapEditMeal: @escaping (DayMeal) -> (),
        didTapMealFoodItem: @escaping (MealFoodItem, DayMeal) -> (),
        onTapAddMeal: @escaping ((Date?) -> ())
    ) {
        self.date = date
        _meals = meals
        self.onTapAddMeal = onTapAddMeal
        self.didTapAddFood = didTapAddFood
        self.didTapEditMeal = didTapEditMeal
        self.didTapMealFoodItem = didTapMealFoodItem
    }
    
    public var body: some View {
        if meals.isEmpty {
            emptyContent
        } else {
//            list
            scrollView
        }
    }
}
