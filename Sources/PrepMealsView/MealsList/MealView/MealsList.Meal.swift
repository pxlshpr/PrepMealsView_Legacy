import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension MealsList {
    struct Meal: View {
        @StateObject var viewModel: ViewModel
        
        var meal: DayMeal

        init(meal: DayMeal) {
            _viewModel = StateObject(wrappedValue: ViewModel(meal: meal))
            self.meal = meal
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
            ForEach(viewModel.foodItems) { item in
                DiaryItemView(item: item)
            }
            Footer(meal: viewModel.meal)
        }
    }
}
