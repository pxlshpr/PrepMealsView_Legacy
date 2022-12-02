import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension MealsList.Meal {
    struct Footer: View {
        @EnvironmentObject var viewModel: MealsList.Meal.ViewModel
        
//        @State var refreshBool = false
        //TODO: CoreData
//        @ObservedObject var meal: Meal
//        @Binding var meal: DayMeal
        
        let didTapAddFood: (DayMeal) -> ()
        
        let didDeleteFoodItemFromMeal = NotificationCenter.default.publisher(for: .didDeleteFoodItemFromMeal)
    }
}

extension MealsList.Meal.Footer {
    var body: some View {
        content
            .background(listRowBackground)
            .onReceive(didDeleteFoodItemFromMeal, perform: didDeleteFoodItemFromMeal)
    }
    
    var listRowBackground: some View {
        let includeTopSeparator = Binding<Bool>(
//            get: { !viewModel.meal.foodItems.isEmpty },
            get: { false },
            set: { _ in }
        )
        return ListRowBackground(includeTopSeparator: includeTopSeparator)
    }
    
    func didDeleteFoodItemFromMeal(notification: Notification) {
        print("We here with: \(viewModel.meal.foodItems.count)")
//        refreshBool.toggle()
    }
    
    var content: some View {
        HStack(spacing: 0) {
            if !viewModel.meal.isCompleted {
                addFoodButton
            }
            Spacer()
            if !viewModel.meal.foodItems.isEmpty {
                energyButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
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
            Text("\(Int(viewModel.meal.energyAmount)) kcal")
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
        didTapAddFood(viewModel.meal)
    }
    
    func tappedEnergy() {
        //TODO: Callback for this
        Haptics.feedback(style: .soft)
    }
}

