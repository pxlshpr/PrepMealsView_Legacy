import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension MealsList {
    struct MealNew: View {
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
    }
}

extension MealsList.MealNew {
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                if isTargeted {
                    Text("We are fucking here")
                        .padding(.vertical)
                }
                items
                footer
            }
            if isTargeted {
                Color.green.opacity(0.3)
            } else {
                Color.clear
            }
        }
        .padding(.horizontal, 15)
        .contentShape(Rectangle())
        .if(viewModel.meal.foodItems.isEmpty) { view in
            view
                .dropDestination(for: MealFoodItem.self) { items, location in
                    print(location)
                    isPresentingConfirm = true
                    return true
                } isTargeted: { isTargeted in
                    withAnimation(.interactiveSpring()) {
                        self.isTargeted = isTargeted
                    }
                }
        }
        .confirmationDialog("Are you sure?", isPresented: $isPresentingConfirm) {
            Button("Move") {
            }
            Button("Duplicate") {
            }
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
                DiaryItemView(item: mealFoodItem)
                    .padding()
                    .background(
                        Color.white
                    )
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
}
