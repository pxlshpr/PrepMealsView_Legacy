import SwiftUI
import SwiftHaptics
import PrepDataTypes

struct MealView: View {
    @StateObject var viewModel: ViewModel
    let namespace: Namespace.ID

    init(meal: Meal, namespace: Namespace.ID) {
        _viewModel = StateObject(wrappedValue: ViewModel(meal: meal))
        self.namespace = namespace
    }

    var body: some View {
        Section {
            Header(
                viewModel: viewModel,
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
