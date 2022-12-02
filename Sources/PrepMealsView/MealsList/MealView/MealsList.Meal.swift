import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension MealsList {
    struct Meal: View {
        @StateObject var viewModel: ViewModel
        @State var draggedMealFoodItem: MealFoodItem? = nil
        
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
            header
            dropDestination
            items
            footer
        }
    }
    
    var header: some View {
        Header()
            .environmentObject(viewModel)
    }
    
    var footer: some View {
        Footer(didTapAddFood: didTapAddFood)
            .environmentObject(viewModel)
    }
    
    @ViewBuilder
    var dropDestination: some View {
        ZStack {
            Color.yellow
            VStack {
                if let draggedMealFoodItem {
                    Text(draggedMealFoodItem.food.name)
                } else {
                    Text("Drag and Drop a food item here here!")
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 100)
        .dropDestination(for: String.self) { items, location in
            print(location)
//            draggedMealFoodItem = items.first
            return true
        } isTargeted: { inDropArea in
            print("In drop area", inDropArea)
        }
    }
    
    var items: some View {
        ForEach(viewModel.meal.foodItems) { mealFoodItem in
            Button {
                didTapMealFoodItem(mealFoodItem, meal)
            } label: {
                DiaryItemView(item: mealFoodItem)
            }
            .draggable("test")
        }
    }
}
