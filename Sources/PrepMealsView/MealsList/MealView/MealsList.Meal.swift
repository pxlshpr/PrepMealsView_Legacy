import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension MealsList {
    struct Meal: View {
        @StateObject var viewModel: ViewModel
        
        let didTapAddFood: (DayMeal) -> ()
        let didTapMealFoodItem: (MealFoodItem, DayMeal) -> ()

        var meal: DayMeal

        init(
            meal: DayMeal,
            didTapAddFood: @escaping (DayMeal) -> (),
            didTapMealFoodItem: @escaping (MealFoodItem, DayMeal) -> ()
        ) {
            _viewModel = StateObject(wrappedValue: ViewModel(meal: meal))
            self.meal = meal
            self.didTapAddFood = didTapAddFood
            self.didTapMealFoodItem = didTapMealFoodItem
        }
    }
}

extension MealsList.Meal {
    var body: some View {
        Section {
            Header(
//                viewModel: viewModel,
//                meal: meal
            )
            .environmentObject(viewModel)
            ForEach(viewModel.meal.foodItems) { mealFoodItem in
                Button {
                    didTapMealFoodItem(mealFoodItem, meal)
                } label: {
                    DiaryItemView(item: mealFoodItem)
                }
            }
            Footer(
//                meal: $viewModel.meal,
                didTapAddFood: didTapAddFood
            )
            .environmentObject(viewModel)
        }
    }
}

