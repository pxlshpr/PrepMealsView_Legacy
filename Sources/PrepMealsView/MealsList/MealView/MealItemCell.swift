import SwiftUI
import SwiftHaptics
import SwiftUISugar
import PrepDataTypes
import PrepViews

struct MealItemCell: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var viewModel: MealsList.Meal.ViewModel
    
    @AppStorage(UserDefaultsKeys.showingFoodMacros) private var showingFoodMacros = false
    
    //TODO: CoreData
    //    @ObservedObject var item: FoodItem
    var item: MealFoodItem
    
    //    @Namespace var localNamespace
    //    var namespace: Binding<Namespace.ID?>
    //    @Binding var namespacePrefix: UUID
    
    var body: some View {
        HStack {
            optionalEmojiText
            nameTexts
            Spacer()
            if showingFoodMacros {
                macrosIndicator
                    .transition(.scale)
            }
            isEatenToggle
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(listRowBackground)
        .dropDestination(
            for: MealFoodItem.self,
            action: handleDrop,
            isTargeted: handleDropIsTargeted
        )
    }
    
    var macrosIndicator: some View {
        let widthBinding = Binding<CGFloat>(
            get: { viewModel.calculateMacrosIndicatorWidth(of: item) },
            set: { _ in }
        )
        return MacrosIndicator(
            c: item.food.info.nutrients.carb,
            f: item.food.info.nutrients.fat,
            p: item.food.info.nutrients.protein,
            width: widthBinding
        )
    }
    
    func handleDrop(_ items: [MealFoodItem], location: CGPoint) -> Bool {
        viewModel.droppedFoodItem = items.first
        viewModel.dropRecipient = item
        return true
    }
    
    func handleDropIsTargeted(_ isTargeted: Bool) {
        Haptics.selectionFeedback()
        withAnimation(.interactiveSpring()) {
            viewModel.dragTargetFoodItemId = isTargeted ? item.id : nil
        }
    }
    
    var listRowBackgroundColor: Color {
        if item.isCompleted {
            return colorScheme == .light ? Color("EBE9F7") : Color("191331")
        } else {
            return Color(.secondarySystemGroupedBackground)
        }
    }
    
    var listRowBackground: some View {
        var isLastCell: Bool {
            viewModel.meal.foodItems.last?.id == item.id
        }
        
        var separator: some View {
            Rectangle()
                .frame(height: 0.18)
                .background(Color(.separator))
                .opacity(colorScheme == .light ? 0.225 : 0.225)
        }
        
        var background: some View {
            Color.white
                .colorMultiply(listRowBackgroundColor)
                .animation(.default, value: item.isCompleted)
        }

        return ZStack {
            background
            VStack {
                Spacer()
                separator
                    .if(!isLastCell, transform: { view in
                        view
                            .padding(.leading, 52)
                    })
            }
        }
    }
    
    var isEatenToggle: some View {
        Button {
            withAnimation {
                //TODO: Bring this back
                //                Store.shared.toggleCompletionForFoodItem(item)
            }
            Haptics.feedback(style: .soft)
        } label: {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle.dotted")
        }
        .foregroundColor(item.isCompleted ? .accentColor : Color(.tertiaryLabel))
        .buttonStyle(.borderless)
    }
    
    @ViewBuilder
    var optionalEmojiText: some View {
        Text(item.food.emoji)
            .font(.body)
        //            .if(namespace.wrappedValue != nil) { view in
        //                view.matchedGeometryEffect(id: "\(item.id.uuidString)-\(namespacePrefix.uuidString)", in: namespace.wrappedValue!)
        //            }
        //            .if(namespace.wrappedValue == nil) { view in
        //                view.matchedGeometryEffect(id: "\(item.id.uuidString)-\(namespacePrefix.uuidString)", in: localNamespace)
        //            }
    }
    
    var nameColor: Color {
        return Color(.label)
        //TODO: Bring this back
        //        guard let meal = item.meal else {
        //            return Color(.secondaryLabel)
        //        }
        //        return meal.isNextPlannedMeal ? Color(.label) : Color(.secondaryLabel)
    }
    
    var amountColor: Color {
        return Color(.secondaryLabel)
        //TODO: Bring this back
        //        guard let meal = item.meal else {
        //            return Color(.quaternaryLabel)
        //        }
        //        return meal.isNextPlannedMeal ? Color(.secondaryLabel) : Color(.quaternaryLabel)
    }
    
    var nameTexts: some View {
        var view = Text(item.food.name)
            .font(.body)
            .fontWeight(.semibold)
            .foregroundColor(nameColor)
        if let detail = item.food.detail, !detail.isEmpty {
            view = view
            + Text(", ")
                .font(.callout)
                .foregroundColor(Color(.secondaryLabel))
            + Text(detail)
                .font(.callout)
                .foregroundColor(Color(.secondaryLabel))
        }
        if let brand = item.food.brand, !brand.isEmpty {
            view = view
            + Text(", ")
                .font(.callout)
                .foregroundColor(Color(.tertiaryLabel))
            + Text(brand)
                .font(.callout)
                .foregroundColor(Color(.tertiaryLabel))
        }
        view = view
        + Text(" • ").foregroundColor(Color(.secondaryLabel))
        + Text(item.quantityDescription)
        
            .font(.callout)
            .fontWeight(.semibold)
            .foregroundColor(amountColor)
        
        return view
            .multilineTextAlignment(.leading)
    }
}



//MARK: - To be moved


extension MealFoodItem {
    var isCompleted: Bool {
        guard let markedAsEatenAt else { return false }
        return markedAsEatenAt > 0
    }
    
    var quantityDescription: String {
        amount.description(with: food)
    }
}

extension FoodValue {
    func description(with food: Food) -> String {
        "\(value.cleanAmount) \(unitDescription(sizes: food.info.sizes))"
    }
}

import UniformTypeIdentifiers

extension MealFoodItem: Transferable {
    
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: MealFoodItem.self, contentType: .mealFoodItem)
        //        CodableRepresentation(contentType: .mealFoodItem)
        //        ProxyRepresentation(exporting: \.id.uuidString)
    }
}

extension UTType {
    static var mealFoodItem: UTType { .init(exportedAs: "com.pxlshpr.Prep.mealFoodItem") }
}

