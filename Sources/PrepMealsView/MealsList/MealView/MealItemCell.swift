import SwiftUI
import SwiftHaptics
import SwiftUISugar
import PrepDataTypes
import PrepViews
import PrepCoreDataStack

struct MealItemCell: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var viewModel: MealView.ViewModel
    
    @AppStorage(UserDefaultsKeys.showingBadgesForFoods) var showingBadgesForFoods = PrepConstants.DefaultPreferences.showingBadgesForFoods
    @AppStorage(UserDefaultsKeys.showingFoodDetails) var showingFoodDetails = PrepConstants.DefaultPreferences.showingFoodDetails
    @AppStorage(UserDefaultsKeys.showingFoodEmojis) var showingFoodEmojis = PrepConstants.DefaultPreferences.showingFoodEmojis

    @Binding var item: MealFoodItem
    @Binding var badgeWidth: CGFloat
    let index: Int
    
    init(item: Binding<MealFoodItem>, index: Int, badgeWidth: Binding<CGFloat>) {
        _item = item
        self.index = index
        _badgeWidth = badgeWidth
    }
    
    var body: some View {
        content
            .background(listRowBackground)
            .dropDestination(
                for: MealFoodItem.self,
                action: handleDrop,
                isTargeted: handleDropIsTargeted
            )
    }
    
    var content: some View {
        HStack(spacing: 0) {
            optionalEmojiText
                .padding(.leading, 10)
            nameTexts
                .padding(.leading, showingFoodEmojis ? 8 : 10)
                .padding(.vertical, 12)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            if showingBadgesForFoods {
                foodBadge
                    .transition(.scale)
                    .padding(.trailing, 10)
                    .opacity(viewModel.hasPassed ? 0.7 : 1)
            }
//            isEatenToggle
        }
    }
    
    var foodBadge: some View {
//        Color.clear
        let widthBinding = Binding<CGFloat>(
//            get: { viewModel.calculateMacrosIndicatorWidth(of: item) },
            //TODO: This needs to be something stored in the cell that gets recalculated dynamically to changes
//            get: { item.macrosIndicatorWidth },
            get: { item.badgeWidth },
            set: { _ in }
        )
        return FoodBadge(
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
    
    var listRowBackground: some View {
        var color: Color {

            return colorScheme == .light
            ? Color(.secondarySystemGroupedBackground)
            : Color(hex: "232323")

            
//            if item.isCompleted {
//                return colorScheme == .light
//                ? Color(hex: "EBE9F7")
////                : Color(hex: "191331")
////                ? Color(hex: "EBE9F7")
////                ? Color(hex: "EBEAEE")
//                : Color(hex: "232323")
//            } else {
//                return colorScheme == .light
////                ? Color(.secondarySystemGroupedBackground)
////                : Color(hex: "232323")
////                ? Color(.secondarySystemGroupedBackground)
//                ? Color(hex: "DFDDF6")
//                : Color(hex: "191331")
//            }
        }
        
        var isLastCell: Bool {
            viewModel.meal.foodItems.last?.id == item.id
        }
        
        var divider: some View {
            Color(hex: colorScheme == .light
                  ? DiaryDividerLineColor.light
                  : DiaryDividerLineColor.dark
            )
            .frame(height: 0.18)
        }

        var separator: some View {
            Color(hex: colorScheme == .light
                  ? DiarySeparatorLineColor.light
                  : DiarySeparatorLineColor.dark
            )
            .frame(height: 0.18)
        }

        var background: some View {
            Color.white
                .colorMultiply(color)
                .animation(.default, value: viewModel.hasPassed)
        }

        return ZStack {
            background
            VStack {
                if viewModel.shouldShowTopSeparator(for: item) {
                    separator
                }
                Spacer()
                if viewModel.shouldShowDivider(for: item) {
                    divider
                        .padding(.leading, 52)
                }
                if viewModel.shouldShowBottomSeparator(for: item) {
                    separator
                }
            }
        }
    }
    
    var isEatenToggle: some View {
        Button {
            withAnimation {
                viewModel.actionHandler(.toggleItemCompletion(item))
                item.markedAsEatenAt = item.isCompleted ? nil : Date().timeIntervalSince1970
            }
            Haptics.feedback(style: .soft)
        } label: {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle.dotted")
                .padding(.leading, 8)
                .padding(.trailing, 20)
                .frame(maxHeight: .infinity)
        }
//        .foregroundColor(item.isCompleted ? .accentColor : Color(.tertiaryLabel))
        .foregroundColor(!item.isCompleted ? .accentColor : Color(.tertiaryLabel))
        .buttonStyle(.borderless)
//        .background(.green)
    }
    
    @ViewBuilder
    var optionalEmojiText: some View {
        if showingFoodEmojis {
            Text(item.food.emoji)
                .font(.body)
                .opacity(viewModel.hasPassed ? 0.7 : 1)
//                .if(namespace.wrappedValue != nil) { view in
//                    view.matchedGeometryEffect(id: "\(item.id.uuidString)-\(namespacePrefix.uuidString)", in: namespace.wrappedValue!)
//                }
//                .if(namespace.wrappedValue == nil) { view in
//                    view.matchedGeometryEffect(id: "\(item.id.uuidString)-\(namespacePrefix.uuidString)", in: localNamespace)
//                }
        }
    }
    
    var nameColor: Color {
//        .primary
        viewModel.hasPassed ? Color(.secondaryLabel) : Color(.label)
//        .primary
//        item.isCompleted ? Color(.secondaryLabel) : Color(.label)
//        return Color(.label)
        //TODO: Bring this back
        //        guard let meal = item.meal else {
        //            return Color(.secondaryLabel)
        //        }
        //        return meal.isNextPlannedMeal ? Color(.label) : Color(.secondaryLabel)
    }
    
    var fontWeight: Font.Weight {
//        .semibold
//        .semibold
        viewModel.hasPassed ? .medium : .semibold
    }
    
    var amountColor: Color {
        return Color(.secondaryLabel)
        //TODO: Bring this back
        //        guard let meal = item.meal else {
        //            return Color(.quaternaryLabel)
        //        }
        //        return meal.isNextPlannedMeal ? Color(.secondaryLabel) : Color(.quaternaryLabel)
    }
    
    var detailFontWeight: Font.Weight {
//        .semibold
        viewModel.hasPassed ? .medium : .semibold
    }
    
    var nameTexts: some View {
        var view = Text(item.food.name)
            .font(.body)
            .fontWeight(fontWeight)
            .foregroundColor(nameColor)
        if showingFoodDetails {
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
        }
        view = view
        + Text(" • ").foregroundColor(Color(.secondaryLabel))
        + Text(item.quantityDescription)
        
            .font(.callout)
            .fontWeight(detailFontWeight)
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


extension MealView.ViewModel {
    var isTargetingLastCell: Bool {
        dragTargetFoodItemId == meal.foodItems.last?.id
    }
    
    var shouldShowFooterTopSeparatorBinding: Binding<Bool> {
        Binding<Bool>(
            get: {
                /// if we're currently targeting last cell, don't show it
                guard !self.isTargetingLastCell else { return false }
                
                /// Otherwise only show it if we're not empty
                return !self.meal.foodItems.isEmpty
            },
            set: { _ in }
        )
    }
    
    func shouldShowTopSeparator(for item: MealFoodItem) -> Bool {
        /// if the meal header is being targeted on and this is the first cell
//        if targetId == meal.id, item.id == meal.foodItems.first?.id {
//            return true
//        }
        
        return false
    }
    
    func shouldShowBottomSeparator(for item: MealFoodItem) -> Bool {
        /// If this cell is being targeted,  and its the last one, show it
//        if item.id == meal.foodItems.last?.id, dragTargetFoodItemId == item.id {
//            return true
//        }
        
        return false
    }

    func shouldShowDivider(for item: MealFoodItem) -> Bool {
        /// if this is the last cell, never show it
        if item.id == meal.foodItems.last?.id {
            return false
        }
        
        /// If this cell is being targeted, don't show it
        if dragTargetFoodItemId == item.id {
            return false
        }
        
        return true
    }
}
