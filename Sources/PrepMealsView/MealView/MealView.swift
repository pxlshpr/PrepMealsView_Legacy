import SwiftUI
import SwiftHaptics
import PrepDataTypes

struct MealView: View {
    @StateObject var viewModel: ViewModel
    
    var meal: DayMeal
    
    var namespace: Binding<Namespace.ID?>
    @Binding var namespacePrefix: UUID
    @Binding var shouldRefresh: Bool
    
    init(
        meal: DayMeal,
        namespace: Binding<Namespace.ID?>,
        namespacePrefix: Binding<UUID>,
        shouldRefresh: Binding<Bool>
    ) {
        _viewModel = StateObject(wrappedValue: ViewModel(meal: meal))
        self.meal = meal
        self.namespace = namespace
        _shouldRefresh = shouldRefresh
        _namespacePrefix = namespacePrefix
    }

    var body: some View {
        Section {
            Header(
                viewModel: viewModel,
                meal: meal,
                namespace: namespace,
                namespacePrefix: $namespacePrefix
            )
            .id(shouldRefresh)
            ForEach(viewModel.foodItems) { item in
                DiaryItemView(
                    item: item,
                    namespace: namespace,
                    namespacePrefix: $namespacePrefix
                )
            }
            Footer(meal: viewModel.meal)
        }
    }
}
