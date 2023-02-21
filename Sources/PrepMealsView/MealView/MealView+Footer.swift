import SwiftUI
import SwiftHaptics
import PrepDataTypes
import SwiftUISugar
import FoodLabel
import PrepCoreDataStack
import PrepViews

extension MealView {
 
    var footerView: some View {
        
        var listRowBackground: some View {
            let binding = Binding<Bool>(
                get: {
                    /// if we're currently targeting last cell, don't show it
                    guard !viewModel.isTargetingLastCell
                    else { return false }
                    
                    /// Otherwise only show it if we're not empty
                    return !foodItems.isEmpty
                },
                set: { _ in }
            )

            return ListRowBackground(includeTopSeparator: binding)
        }

        return ZStack(alignment: .bottom) {
            HStack(spacing: 0) {
                Spacer()
                optionalNutrientsButton
            }
            .padding(.trailing, 20)
            .frame(height: 50)
            .background(listRowBackground)
            HStack(spacing: 0) {
                addFoodButton
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
    
    @ViewBuilder
    var optionalNutrientsButton: some View {
        if !foodItems.isEmpty {
            nutrientsButton
                .fixedSize()
        }
    }

    var nutrientsButton: some View {
        
        var energyLabel: some View {
            Color.clear
                .animatedFooterEnergyValue(value: meal.energyValueInKcal)
        }
        
        var energyLabel_legacy: some View {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(meal.energyValueInKcal))")
                    .foregroundColor(Color(.secondaryLabel))
                    .font(.footnote)
                Text("kcal")
                    .foregroundColor(Color(.tertiaryLabel))
                    .font(.caption2)
            }
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
//    func tappedAddFood() {
////        Haptics.feedback(style: .soft)
//        viewModel.actionHandler(.addFood(viewModel.meal))
////        viewModel.didTapAddFood(viewModel.meal)
//    }
    
    func tappedEnergy() {
        //TODO: Callback for this
        Haptics.feedback(style: .soft)
    }

}

struct AnimatableFooterEnergyValue: AnimatableModifier {
    
    @Environment(\.colorScheme) var colorScheme
    @State var size: CGSize = .zero
    
    var value: Double
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: size.width, height: size.height)
            .overlay(
                animatedLabel
                    .readSize { size in
                        self.size = size
                    }
            )
    }
    
    var animatedLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value.formattedEnergy)
                .foregroundColor(Color(.secondaryLabel))
                .font(.footnote)
            Text("kcal")
                .foregroundColor(Color(.tertiaryLabel))
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: true, vertical: false)
    }
}

extension View {
    func animatedFooterEnergyValue(value: Double) -> some View {
        modifier(AnimatableFooterEnergyValue(value: value))
    }
}
