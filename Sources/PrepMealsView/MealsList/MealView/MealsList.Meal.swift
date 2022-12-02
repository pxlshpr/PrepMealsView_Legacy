import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension MealsList {
    struct Meal: View {
        @Environment(\.colorScheme) var colorScheme
        @StateObject var viewModel: MealsList.Meal.ViewModel
        
        let didTapAddFood: (DayMeal) -> ()
        let didTapMealFoodItem: (MealFoodItem, DayMeal) -> ()
        
        var meal: DayMeal
        
        init(
            meal: DayMeal,
            didTapAddFood: @escaping (DayMeal) -> (),
            didTapMealFoodItem: @escaping (MealFoodItem, DayMeal) -> ()
        ) {
            _viewModel = StateObject(wrappedValue: MealsList.Meal.ViewModel(meal: meal))
            self.meal = meal
            self.didTapAddFood = didTapAddFood
            self.didTapMealFoodItem = didTapMealFoodItem
        }
        
        @State var targetId: UUID? = nil
        @State var showingDropOptions: Bool = false
//        @State var droppedFoodItem: MealFoodItem? = nil
    }
}

extension MealsList.Meal {
    var body: some View {
        content
            .contentShape(Rectangle())
            .onChange(of: viewModel.droppedFoodItem, perform: droppedFoodItemChanged)
            .if(viewModel.isEmpty) { view in
                view
                    .dropDestination(
                        for: MealFoodItem.self,
                        action: handleDrop,
                        isTargeted: handleDropIsTargeted
                    )
            }
            .confirmationDialog(
                dropConfirmationTitle,
                isPresented: $showingDropOptions,
                titleVisibility: .visible,
                actions: dropConfirmationActions
            )
    }
    
    func droppedFoodItemChanged(to droppedFoodItem: MealFoodItem?) {
        showingDropOptions = droppedFoodItem != nil
    }
    
    var content: some View {
        VStack(spacing: 0) {
            header
            dropTargetForMeal
            mealContent
            footer
        }
    }
    
    var header: some View {
        MealsList.Meal.Header()
            .environmentObject(viewModel)
            .contentShape(Rectangle())
            .if(!viewModel.isEmpty, transform: { view in
                view
                    .dropDestination(
                        for: MealFoodItem.self,
                        action: handleDrop,
                        isTargeted: handleDropIsTargeted
                    )
            })
    }
    
    @ViewBuilder
    var footer: some View {
        MealsList.Meal.Footer(didTapAddFood: didTapAddFood)
            .environmentObject(viewModel)
    }
    
    @ViewBuilder
    var mealContent: some View {
        itemRows
    }
    
    var itemRows: some View {
        ForEach(viewModel.meal.foodItems) { mealFoodItem in
            cell(for: mealFoodItem)
            dropTargetView(for: mealFoodItem)
        }
    }
    
    @ViewBuilder
    func dropTargetView(for mealFoodItem: MealFoodItem) -> some View {
        if let id = viewModel.dragTargetFoodItemId,
            mealFoodItem.id == id
        {
            dropTargetView
                .padding(.top, 12)
                .if(viewModel.meal.foodItems.last?.id != mealFoodItem.id) {
                    $0.padding(.bottom, 12)
                }
        }
    }
    
    func cell(for mealFoodItem: MealFoodItem) -> some View {
        Button {
            didTapMealFoodItem(mealFoodItem, meal)
        } label: {
            MealItemCell(item: mealFoodItem)
                .environmentObject(viewModel)
        }
        .draggable(mealFoodItem)
        .transition(
            .asymmetric(
                insertion: .move(edge: .top),
//                removal: .move(edge: .top)
                removal: .scale
            )
        )
    }
    
    //MARK: - Drag and Drop related
    
    @ViewBuilder
    var dropTargetForMeal: some View {
        if let targetId, targetId == meal.id {
            dropTargetView
                .if(!viewModel.isEmpty) { view in
                    view.padding(.bottom, 12)
                }
        }
    }
    
    var dropTargetView: some View {
        Text("Drop food here")
            .bold()
            .foregroundColor(.primary)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .foregroundColor(
                        Color.accentColor.opacity(colorScheme == .dark ? 0.4 : 0.2)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(
                        Color(.tertiaryLabel),
                        style: StrokeStyle(lineWidth: 1, dash: [5])
                    )
            )
            .padding(.horizontal, 12)
    }
    
    var dropConfirmationTitle: String {
        guard let droppedFoodItem = viewModel.droppedFoodItem else { return "" }
        return droppedFoodItem.description
    }
    
    @ViewBuilder
    func dropConfirmationActions() -> some View {
        Button("Move") {
            viewModel.tappedMoveForDrop()
        }
        Button("Duplicate") {
            viewModel.tappedDuplicateForDrop()
        }
    }
    
    func handleDrop(_ items: [MealFoodItem], location: CGPoint) -> Bool {
        viewModel.droppedFoodItem = items.first
//        droppedFoodItem = items.first
//        showingDropOptions = true
        return true
    }
    
    func handleDropIsTargeted(_ isTargeted: Bool) {
        Haptics.selectionFeedback()
        withAnimation(.interactiveSpring()) {
            self.targetId = isTargeted ? viewModel.meal.id : nil
        }
    }
}

extension MealFoodItem {
    var description: String {
        "\(food.name) • \(quantityDescription)"
    }
}
