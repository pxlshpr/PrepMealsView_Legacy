import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension MealsList {
    struct Meal: View {
        @StateObject var viewModel: ViewModel
        
        var meal: DayMeal
        let onTapMealMenu: (DayMeal) -> ()

        init(meal: DayMeal, onTapMealMenu: @escaping (DayMeal) -> ()) {
            _viewModel = StateObject(wrappedValue: ViewModel(meal: meal))
            self.meal = meal
            self.onTapMealMenu = onTapMealMenu
        }
    }
}

extension MealsList.Meal {
    var body: some View {
        Section {
            Header(
                viewModel: viewModel,
                meal: meal,
                onTapMealMenu: onTapMealMenu
            )
            ForEach(viewModel.foodItems) { item in
                DiaryItemView(item: item)
            }
            Footer(meal: viewModel.meal)
        }
    }
}
