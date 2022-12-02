import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension MealsList {
    struct Meal: View {
        @StateObject var viewModel: MealsList.Meal.ViewModel
        @State var draggedMealFoodItem: MealFoodItem? = nil
        
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
        
        @State var isTargeted: Bool = false
        
        @State var isPresentingConfirm: Bool = false
        @State var droppedFoodItem: MealFoodItem? = nil
    }
}

extension MealsList.Meal {
    var body: some View {
        content
            .contentShape(Rectangle())
            .if(viewModel.meal.foodItems.isEmpty) { view in
                view
                    .dropDestination(
                        for: MealFoodItem.self,
                        action: handleDrop,
                        isTargeted: handleDropIsTargeted
                    )
            }
            .confirmationDialog(
                dropConfirmationTitle,
                isPresented: $isPresentingConfirm,
                titleVisibility: .visible,
                actions: dropConfirmationActions
            )
    }
    
    var content: some View {
        VStack(spacing: 0) {
            header
            dropTargetView
            items
            footer
        }
    }
    
    var header: some View {
        MealsList.Meal.Header()
            .environmentObject(viewModel)
    }
    
    var footer: some View {
        MealsList.Meal.Footer(didTapAddFood: didTapAddFood)
            .environmentObject(viewModel)
    }
    
    var items: some View {
        ForEach(viewModel.meal.foodItems) { mealFoodItem in
            Button {
                didTapMealFoodItem(mealFoodItem, meal)
            } label: {
                //                DiaryItemView(item: mealFoodItem)
                MealItemCell(item: mealFoodItem)
                    .dropDestination(for: MealFoodItem.self) { items, location in
                        print(location)
                        draggedMealFoodItem = items.first
                        return true
                    } isTargeted: { isTargeted in
                        //                        self.isTargeted = isTargeted
                    }
            }
            .draggable(mealFoodItem)
            .transition(.asymmetric(insertion: .move(edge: .top),
                                    removal: .scale))
        }
    }
    
    //MARK: - Drag and Drop related
    @ViewBuilder
    var dropTargetView: some View {
        if isTargeted {
            Text("Drop food here")
                .bold()
                .foregroundColor(.secondary)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .foregroundColor(
                            Color.accentColor.opacity(0.4)
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
    }
    
    var dropConfirmationTitle: String {
        guard let droppedFoodItem else { return "" }
        return droppedFoodItem.description
    }
    
    @ViewBuilder
    func dropConfirmationActions() -> some View {
        Button("Move") {
            guard let droppedFoodItem else { return }
            print("Time to move \(droppedFoodItem.description) to \(self.meal.name)")
        }
        Button("Duplicate") {
            guard let droppedFoodItem else { return }
            print("Time to move \(droppedFoodItem.description) to \(self.meal.name)")
        }
    }
    
    func handleDrop(_ items: [MealFoodItem], location: CGPoint) -> Bool {
        droppedFoodItem = items.first
        isPresentingConfirm = true
        return true
    }
    
    func handleDropIsTargeted(_ isTargeted: Bool) {
        Haptics.selectionFeedback()
        withAnimation(.interactiveSpring()) {
            self.isTargeted = isTargeted
        }
    }
}

extension MealFoodItem {
    var description: String {
        "\(food.name) • \(quantityDescription)"
    }
}
