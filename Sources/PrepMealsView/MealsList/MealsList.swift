import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftSugar

public struct MealsList: View {
    
    let actionHandler: (MealsDiaryAction) -> ()
//    let onTapAddMeal: ((Date?) -> ())
//    let didTapAddFood: ((DayMeal) -> ())
//    let didTapEditMeal: ((DayMeal) -> ())
//    let didTapMealFoodItem: ((MealFoodItem, DayMeal) -> ())

    let date: Date
    @Binding var meals: [DayMeal]
    
    @Environment(\.colorScheme) var colorScheme

    @State var animation: Animation? = .none
    
    public init(
        date: Date,
        meals: Binding<[DayMeal]>,
        actionHandler: @escaping (MealsDiaryAction) -> ()
//        didTapAddFood: @escaping (DayMeal) -> (),
//        didTapEditMeal: @escaping (DayMeal) -> (),
//        didTapMealFoodItem: @escaping (MealFoodItem, DayMeal) -> (),
//        onTapAddMeal: @escaping ((Date?) -> ())
    ) {
        self.date = date
        _meals = meals
        self.actionHandler = actionHandler
//        self.onTapAddMeal = onTapAddMeal
//        self.didTapAddFood = didTapAddFood
//        self.didTapEditMeal = didTapEditMeal
//        self.didTapMealFoodItem = didTapMealFoodItem
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
