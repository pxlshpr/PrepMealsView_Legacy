import SwiftUI
import SwiftHaptics
import PrepDataTypes
import PrepViews

extension MealView {
    struct Footer: View {
        @Environment(\.colorScheme) var colorScheme
        @EnvironmentObject var viewModel: MealView.ViewModel
        
        @AppStorage(UserDefaultsKeys.showingBadgesForFoods) var showingBadgesForFoods = PrepConstants.DefaultPreferences.showingBadgesForFoods

//        @State var refreshBool = false
        //TODO: CoreData
//        @ObservedObject var meal: Meal
//        @Binding var meal: DayMeal
        
//        let didTapAddFood: (DayMeal) -> ()
        
        let didDeleteFoodItemFromMeal = NotificationCenter.default.publisher(for: .didDeleteFoodItemFromMeal)
        
        let meal: DayMeal
        
        init(meal: DayMeal) {
            self.meal = meal
        }
    }
}

extension MealView.Footer {
    var body: some View {
        content
            .onReceive(didDeleteFoodItemFromMeal, perform: didDeleteFoodItemFromMeal)
//            .background(.yellow)
    }
    
    var listRowBackground: some View {
        ListRowBackground(includeTopSeparator: viewModel.shouldShowFooterTopSeparatorBinding)
    }
    
    func didDeleteFoodItemFromMeal(notification: Notification) {
//        refreshBool.toggle()
    }
    
    @ViewBuilder
    var optionalFoodButton: some View {
//        if !viewModel.meal.isCompleted {
            addFoodButton
//        }
    }
    
    @ViewBuilder
    var optionalNutrientsButton: some View {
        if !viewModel.meal.foodItems.isEmpty {
            nutrientsButton
                .fixedSize()
        }
    }
    
    var content: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: 0) {
                Spacer()
                optionalNutrientsButton
            }
            .padding(.trailing, 20)
            .frame(height: 50)
            .background(listRowBackground)
            HStack(spacing: 0) {
                optionalFoodButton
                Spacer()
            }
            .frame(height: 65)
        }
    }
    
    var addFoodButton: some View {
        var label: some View {
            Text(viewModel.isInFuture ? "Prep Food" : "Log Food")
                .font(.caption)
                .bold()
                .foregroundColor(.accentColor)
                .padding(.horizontal, 8)
                .frame(height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.accentColor.opacity(
                            colorScheme == .dark ? 0.1 : 0.15
                        ))
                )
                .frame(maxHeight: .infinity)
                .padding(.leading, 20)
                .padding(.top, 22.75)
        }
        
        var label_legacy: some View {
            Text("Add Food")
                .font(.caption)
                .bold()
                .padding(.horizontal, 8)
                .frame(height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(Color(.tertiarySystemFill))
                )
                .frame(maxHeight: .infinity)
                .padding(.leading, 20)
                .padding(.top, 22.75)
//                .background(.green)
        }
        
        var button: some View {
            return Button {
                tappedAddFood()
            } label: {
                label
            }
        }
        
        return button
//        return label
            .onTapGesture { tappedAddFood() }
            .contentShape(Rectangle())
            .padding(.trailing)
            .buttonStyle(.borderless)
    }

    var nutrientsButton: some View {
        var energyLabel: some View {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(viewModel.meal.energyValueInKcal))")
                    .foregroundColor(Color(.secondaryLabel))
                Text("kcal")
                    .foregroundColor(Color(.tertiaryLabel))
                    .font(.caption2)
            }
            .font(.footnote)
        }
        
        //TODO: Look into why this binding of the width still doesn't fix it? Maybe the calculation is wrong
        var foodBadge: some View {
//            Color.clear
            let binding = Binding<CGFloat>(
                get: {
//                    viewModel.meal.badgeWidth
                    meal.badgeWidth
                },
                set: { _ in }
            )
            return FoodBadge(
                c: viewModel.meal.scaledValueForMacro(.carb),
                f: viewModel.meal.scaledValueForMacro(.fat),
                p: viewModel.meal.scaledValueForMacro(.protein),
                width: binding
            )
        }
        
        var label: some View {
            HStack {
//                if showingMealMacros {
                if !showingBadgesForFoods {
                    foodBadge
                        .transition(.scale)
                }
                energyLabel
            }
        }
        
        var button: some View {
            return Button {
                tappedEnergy()
            } label: {
                label
            }
        }
        
        return button
//        return label
            .onTapGesture { tappedEnergy() }
            .contentShape(Rectangle())
            .padding(.leading)
            .buttonStyle(.borderless)
            .frame(maxHeight: .infinity)
    }
    
    //MARK: - Actions
    func tappedAddFood() {
//        Haptics.feedback(style: .soft)
        viewModel.actionHandler(.addFood(viewModel.meal))
//        viewModel.didTapAddFood(viewModel.meal)
    }
    
    func tappedEnergy() {
        //TODO: Callback for this
        Haptics.feedback(style: .soft)
    }
}

