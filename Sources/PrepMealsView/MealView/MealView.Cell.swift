import SwiftUI
import SwiftHaptics
import SwiftUISugar
import PrepDataTypes
import PrepViews
import PrepCoreDataStack

extension MealView {
    struct Cell: View {
        @Environment(\.colorScheme) var colorScheme
        
        @EnvironmentObject var viewModel: MealView.ViewModel
        
        @AppStorage(UserDefaultsKeys.showingBadgesForFoods) var showingBadgesForFoods = PrepConstants.DefaultPreferences.showingBadgesForFoods
        @AppStorage(UserDefaultsKeys.showingFoodDetails) var showingFoodDetails = PrepConstants.DefaultPreferences.showingFoodDetails
        @AppStorage(UserDefaultsKeys.showingFoodEmojis) var showingFoodEmojis = PrepConstants.DefaultPreferences.showingFoodEmojis

        let item: MealFoodItem
       
        @Binding var dragTargetFoodItemId: UUID?
        
        @Binding var showingDropOptions: Bool
        @Binding var isLastItemOfMeal: Bool
        @Binding var isMovingItem: Bool
        @State var shouldShowDropTargetView: Bool = false
        
        init(
            item: MealFoodItem,
            showingDropOptions: Binding<Bool>,
            dragTargetFoodItemId: Binding<UUID?>,
            isLastItemOfMeal: Binding<Bool>,
            isMovingItem: Binding<Bool>
        ) {
            _isMovingItem = isMovingItem
            _isLastItemOfMeal = isLastItemOfMeal
            _showingDropOptions = showingDropOptions
            _dragTargetFoodItemId = dragTargetFoodItemId
            self.item = item
        }
    }
}

extension MealView.Cell {
    
    var body: some View {
        VStack(spacing: 0) {
            content
                .background(listRowBackground)
                .dropDestination(
                    for: MealFoodItem.self,
                    action: handleDrop,
                    isTargeted: handleDropIsTargeted
                )
                .onChange(of: showingDropOptions, perform: showingDropOptionsChanged)
                .onChange(of: dragTargetFoodItemId, perform: dragTargetFoodItemIdChanged)
                .onChange(of: viewModel.dropRecipient, perform: dropRecipientChanged)
            optionalDropTargetView
        }
    }
    
    func dropRecipientChanged(_ newValue: MealFoodItem?) {
        updateShouldShowDropTargetView()
    }
    
    func dragTargetFoodItemIdChanged(_ newValue: UUID?) {
        updateShouldShowDropTargetView()
    }
    
    func showingDropOptionsChanged(_ newValue: Bool) {
        updateShouldShowDropTargetView()
    }
    
    func updateShouldShowDropTargetView() {
        if isMovingItem {
            self.shouldShowDropTargetView = getShouldShowDropTargetView()
        } else {
            withAnimation(.interactiveSpring()) {
                self.shouldShowDropTargetView = getShouldShowDropTargetView()
            }
        }
    }
    
    @ViewBuilder
    var optionalDropTargetView: some View {
       if shouldShowDropTargetView {
            dropTargetView
                .padding(.top, 12)
                .if(!isLastItemOfMeal) {
                    $0.padding(.bottom, 12)
                }
        }
    }

    func getShouldShowDropTargetView() -> Bool {
        if let dragTargetFoodItemId, item.id == dragTargetFoodItemId {
            return true
        }
        
        if showingDropOptions,
           let dropRecipient = viewModel.dropRecipient,
           dropRecipient.id == item.id
        {
            return true
        }
        
        return false
    }
    
    var dropTargetView: some View {
//        Text("Move or Duplicate Here")
        Text("Drop Here")
            .bold()
//            .foregroundColor(.primary)
            .foregroundColor(.secondary)
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
            .transition(.opacity)
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
        }
    }
    
    var foodBadge: some View {
        let widthBinding = Binding<CGFloat>(
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
        print("🤳 \(item.food.name) isTargeted changed to: \(isTargeted)")
        
        Haptics.selectionFeedback()
        withAnimation(.interactiveSpring()) {
            dragTargetFoodItemId = isTargeted ? item.id : nil
        }
    }
    
    var listRowBackground: some View {
        var color: Color {
            return colorScheme == .light
            ? Color(.secondarySystemGroupedBackground)
            : Color(hex: "232323")
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
    
    @ViewBuilder
    var optionalEmojiText: some View {
        if showingFoodEmojis {
            Text(item.food.emoji)
                .font(.body)
                .opacity(viewModel.hasPassed ? 0.7 : 1)
        }
    }
    
    var nameColor: Color {
        viewModel.hasPassed ? Color(.secondaryLabel) : Color(.label)
    }
    
    var fontWeight: Font.Weight {
        .medium
//        viewModel.hasPassed ? .medium : .semibold
    }
    
    var amountColor: Color {
        Color(.secondaryLabel)
    }
    
    var detailFontWeight: Font.Weight {
        .regular
//        .medium
//        viewModel.hasPassed ? .medium : .semibold
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

extension MealView.Cell {
    struct DragPreview: View {
        let item: MealFoodItem
    }
}

extension MealView.Cell.DragPreview {
    var body: some View {
        HStack(spacing: 2) {
            Text(item.food.emoji)
                .font(.largeTitle)
            Text(item.food.name)
                .font(.title3)
//                .bold()
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(3)
        .clippedText()
        .background(Color(.systemBackground))
        .frame(width: 200)
        .contentShape([.dragPreview], RoundedRectangle(cornerRadius: 12))
    }
}

struct ClippedText: ViewModifier {
    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            content.hidden().layoutPriority(1)
            content.fixedSize(horizontal: true, vertical: false)
            HStack {
                Spacer()
                LinearGradient(colors: [.clear, Color(.systemBackground)], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 50)
            }
        }
        .clipped()
    }
}

extension View {
    func clippedText() -> some View {
        self.modifier(ClippedText())
    }
}
