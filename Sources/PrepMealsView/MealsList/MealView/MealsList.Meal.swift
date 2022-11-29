import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension MealsList {
    struct Meal: View {
        @StateObject var viewModel: ViewModel
        
        let didTapAddFood: (DayMeal) -> ()
        
        var meal: DayMeal

        init(
            meal: DayMeal,
            didTapAddFood: @escaping (DayMeal) -> ()
        ) {
            _viewModel = StateObject(wrappedValue: ViewModel(meal: meal))
            self.meal = meal
            self.didTapAddFood = didTapAddFood
        }
    }
}

extension MealsList.Meal {
    var body: some View {
        Section {
            Header(
                viewModel: viewModel,
                meal: meal
            )
            ForEach(viewModel.foodItems) { mealFoodItem in
                DiaryItemView(item: mealFoodItem)
            }
            Footer(
                meal: viewModel.meal,
                didTapAddFood: didTapAddFood
            )
        }
    }
}
