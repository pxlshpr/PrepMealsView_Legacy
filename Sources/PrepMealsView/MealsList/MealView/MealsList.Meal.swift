import SwiftUI
import SwiftHaptics
import PrepDataTypes
import SwiftUISugar

extension MealsList {
    struct Meal: View {
        @Environment(\.colorScheme) var colorScheme
        @StateObject var viewModel: MealsList.Meal.ViewModel
        
//        let didTapAddFood: (DayMeal) -> ()
//        let didTapMealFoodItem: (MealFoodItem, DayMeal) -> ()
        
//        var meal: DayMeal
        
        @Binding var badgeWidths: [UUID : CGFloat]
        @Binding var isUpcomingMeal: Bool
        
        init(
            date: Date,
            meal: DayMeal,
//            meals: [DayMeal],
            badgeWidths: Binding<[UUID : CGFloat]>,
            isUpcomingMeal: Binding<Bool>,
            actionHandler: @escaping (MealsDiaryAction) -> ()
//            didTapAddFood: @escaping (DayMeal) -> (),
//            didTapEditMeal: @escaping (DayMeal) -> (),
//            didTapMealFoodItem: @escaping (MealFoodItem, DayMeal) -> ()
        ) {
            let viewModel = MealsList.Meal.ViewModel(
                date: date,
                meal: meal,
                isUpcomingMeal: isUpcomingMeal.wrappedValue,
//                meals: meals,
                actionHandler: actionHandler
//                didTapAddFood: didTapAddFood,
//                didTapEditMeal: didTapEditMeal,
//                didTapMealFoodItem: didTapMealFoodItem
            )
            _badgeWidths = badgeWidths
            _isUpcomingMeal = isUpcomingMeal
            _viewModel = StateObject(wrappedValue: viewModel)
//            self.meal = meal
//            self.didTapAddFood = didTapAddFood
//            self.didTapMealFoodItem = didTapMealFoodItem
        }

        @State var showingDropOptions: Bool = false
//        @State var droppedFoodItem: MealFoodItem? = nil
    }
}

extension MealsList.Meal {
    var body: some View {
        content
            .contentShape(Rectangle())
            .onChange(of: viewModel.droppedFoodItem, perform: droppedFoodItemChanged)
            .onChange(of: showingDropOptions, perform: showingDropOptionsChanged)
            .onChange(of: isUpcomingMeal, perform: isUpcomingMealChanged)
            .if(viewModel.isEmpty) { view in
                view
                    .dropDestination(
                        for: MealFoodItem.self,
                        action: handleDrop,
                        isTargeted: handleDropIsTargeted
                    )
            }
            .confirmationDialog(
                dropConfirmationTitle,
                isPresented: $showingDropOptions,
                titleVisibility: .visible,
                actions: dropConfirmationActions
            )
            .onChange(of: isUpcomingMeal) { newValue in
                withAnimation {
                    viewModel.isUpcomingMeal = newValue
                }
            }
    }
    
    func isUpcomingMealChanged(_ newValue: Bool) {
        viewModel.isUpcomingMeal = newValue
    }
    
    func droppedFoodItemChanged(to droppedFoodItem: MealFoodItem?) {
        showingDropOptions = droppedFoodItem != nil
    }
    
    func showingDropOptionsChanged(to newValue: Bool) {
        if !showingDropOptions {
            viewModel.resetDrop()
        }
    }
    
    var content: some View {
        ZStack {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 44)
                dropTargetForMeal
                mealContent
                Color.clear
                    .frame(height: 50)
            }
            VStack(spacing: 0) {
                header
                Spacer()
            }
            VStack(spacing: 0) {
                Spacer()
                footer
            }
        }
    }
    
    var content_legacy: some View {
        ZStack {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 44)
                dropTargetForMeal
                mealContent
                Color.clear
                    .frame(height: 50)
            }
            VStack(spacing: 0) {
                header
                Spacer()
            }
            VStack(spacing: 0) {
                Spacer()
                footer
            }
        }
    }
    
    var header: some View {
        MealsList.Meal.Header()
            .environmentObject(viewModel)
            .contentShape(Rectangle())
            .if(!viewModel.isEmpty, transform: { view in
                view
                    .dropDestination(
                        for: MealFoodItem.self,
                        action: handleDrop,
                        isTargeted: handleDropIsTargeted
                    )
            })
    }
    
    var footer: some View {
        let binding = Binding<CGFloat>(
            get: { badgeWidths[viewModel.meal.id] ?? 0 },
            set: { _ in }
        )
        return MealsList.Meal.Footer(
            badgeWidth: binding
        )
        .environmentObject(viewModel)
    }
    
    @ViewBuilder
    var mealContent: some View {
        itemRows
//        list
    }
    
    var list: some View {
        List {
            ForEach(viewModel.meal.foodItems.indices, id: \.self) { index in
                cell(for: $viewModel.meal.foodItems[index], index: index)
            }
        }
    }
    
    var itemRows: some View {
        ForEach(viewModel.meal.foodItems.indices, id: \.self) { index in
//            cell(at: index)
            cell(for: $viewModel.meal.foodItems[index], index: index)
            dropTargetView(for: viewModel.meal.foodItems[index])
        }
    }
    
    @ViewBuilder
    func dropTargetView(for mealFoodItem: MealFoodItem) -> some View {
        if let id = viewModel.dragTargetFoodItemId,
            mealFoodItem.id == id
        {
            dropTargetView
                .padding(.top, 12)
                .if(viewModel.meal.foodItems.last?.id != mealFoodItem.id) {
                    $0.padding(.bottom, 12)
                }
        }
    }

    func cell(at index: Int) -> some View {
        Button {
        } label: {
            ZStack {
                Color.yellow
                Text(viewModel.meal.foodItems[index].food.name)
            }
            .frame(height: 40)
        }
    }
    
    func cell(for mealFoodItem: Binding<MealFoodItem>, index: Int) -> some View {
        
        let badgeWidthBinding = Binding<CGFloat>(
            get: {
                badgeWidths[mealFoodItem.id] ?? 0
            },
            set: { _ in }
        )
        
        var label: some View {
            var yellow: some View {
                ZStack {
                    Color.yellow
                    Text(viewModel.meal.foodItems[index].food.name)
                }
                .frame(height: 40)
            }
            var mealItemCell: some View {
                MealItemCell(
                    item: mealFoodItem,
                    index: index,
                    badgeWidth: badgeWidthBinding
                )
                .environmentObject(viewModel)
            }
            
//            return yellow
            return mealItemCell
        }
        
        var button: some View {
            Button {
                viewModel.actionHandler(.editFoodItem(mealFoodItem.wrappedValue, viewModel.meal))
    //            viewModel.didTapMealFoodItem(mealFoodItem, viewModel.meal)
            } label: {
                label
            }
        }
        
        
        var asLabel: some View {
            label
                .onTapGesture {
                    viewModel.actionHandler(.editFoodItem(mealFoodItem.wrappedValue, viewModel.meal))
                }
        }
        
        return button
//        return asLabel
//        .draggable(mealFoodItem.wrappedValue)
            .contextMenu(menuItems: {
                Section("Title goes here") {
                    Button("Edit") {
                        
                    }
                    Button("Other stuff") {
                        
                    }
                    Divider()
                    Button("delete", role: .destructive) {
                        
                    }
                }
//            }, preview: {
//                VStack(alignment: .leading) {
//                    HStack {
//                        Text(mealFoodItem.wrappedValue.food.emoji)
//                        Text(mealFoodItem.wrappedValue.food.name)
//                    }
//                    if let detail = mealFoodItem.wrappedValue.food.detail {
//                        Text(detail)
//                    }
//                    if let brand = mealFoodItem.wrappedValue.food.brand {
//                        Text(brand)
//                    }
//                }
            })
        .transition(
            .asymmetric(
                insertion: .move(edge: .top),
                removal: .scale
            )
        )
    }
    
    //MARK: - Drag and Drop related
    
    @ViewBuilder
    var dropTargetForMeal: some View {
        if viewModel.targetId == viewModel.meal.id {
            dropTargetView
                .if(!viewModel.isEmpty) { view in
                    view.padding(.bottom, 12)
                }
        }
    }
    
    var dropTargetView: some View {
        Text("Drop food here")
            .bold()
            .foregroundColor(.primary)
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
    }
    
    var dropConfirmationTitle: String {
        guard let droppedFoodItem = viewModel.droppedFoodItem else { return "" }
        return droppedFoodItem.description
    }
    
    @ViewBuilder
    func dropConfirmationActions() -> some View {
        Button("Move") {
            viewModel.tappedMoveForDrop()
        }
        Button("Duplicate") {
            viewModel.tappedDuplicateForDrop()
        }
    }
    
    func handleDrop(_ items: [MealFoodItem], location: CGPoint) -> Bool {
        viewModel.droppedFoodItem = items.first
//        droppedFoodItem = items.first
//        showingDropOptions = true
        return true
    }
    
    func handleDropIsTargeted(_ isTargeted: Bool) {
        Haptics.selectionFeedback()
        withAnimation(.interactiveSpring()) {
            viewModel.targetId = isTargeted ? viewModel.meal.id : nil
        }
    }
}

extension MealFoodItem {
    var description: String {
        "\(food.name) • \(quantityDescription)"
    }
}
