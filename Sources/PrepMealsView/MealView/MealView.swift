import SwiftUI
import SwiftHaptics
import PrepDataTypes

struct MealView: View {
    @StateObject var viewModel: ViewModel
    let namespace: Namespace.ID

    var meal: Meal
    
    init(meal: Meal, namespace: Namespace.ID) {
        _viewModel = StateObject(wrappedValue: ViewModel(meal: meal))
        self.meal = meal
        self.namespace = namespace
    }

    var body: some View {
        Section {
            Header(
                viewModel: viewModel,
                meal: meal,
                namespace: namespace
            )
            ForEach(viewModel.foodItems) { item in
                DiaryItemView(
                    item: item,
                    namespace: namespace
                )
            }
            Footer(meal: viewModel.meal)
        }
    }
}
