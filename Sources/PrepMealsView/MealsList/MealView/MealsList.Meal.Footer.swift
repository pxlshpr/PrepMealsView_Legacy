import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension MealsList.Meal {
    struct Footer: View {
        //TODO: CoreData
//        @ObservedObject var meal: Meal
        var meal: DayMeal
        
        let didTapAddFood: (DayMeal) -> ()
    }
}

extension MealsList.Meal.Footer {
    var body: some View {
        content
        .listRowBackground(
            ListRowBackground(
                includeTopSeparator: !meal.foodItems.isEmpty
            )
        )
        .listRowInsets(.none)
        .listRowSeparator(.hidden)
    }
    
    var content: some View {
        HStack(spacing: 0) {
            if !meal.isCompleted {
                addFoodButton
            }
            Spacer()
            if !meal.foodItems.isEmpty {
                energyButton
            }
        }
    }
    
    var addFoodButton: some View {
        Button {
            tappedAddFood()
        } label: {
            Text("Add Food")
                .font(.caption)
                .bold()
//                .foregroundColor(.secondary)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(Color(.tertiarySystemFill))
                )
        }
        .contentShape(Rectangle())
        .padding(.trailing)
        .buttonStyle(.borderless)
        .frame(maxHeight: .infinity)
    }

    var energyButton: some View {
        Button {
            tappedEnergy()
        } label: {
            Text("\(Int(meal.energyAmount)) kcal")
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel))
        }
        .contentShape(Rectangle())
        .padding(.leading)
        .buttonStyle(.borderless)
        .frame(maxHeight: .infinity)
    }
    
    //MARK: - Actions
    func tappedAddFood() {
        Haptics.feedback(style: .soft)
        didTapAddFood(meal)
    }
    
    func tappedEnergy() {
        //TODO: Callback for this
        Haptics.feedback(style: .soft)
    }
}

