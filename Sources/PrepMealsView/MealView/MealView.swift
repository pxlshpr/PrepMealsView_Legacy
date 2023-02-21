import SwiftUI
import SwiftHaptics
import PrepDataTypes
import SwiftUISugar
import FoodLabel

struct MealView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel: ViewModel
    @Binding var isUpcomingMeal: Bool
    @Binding var isAnimatingItemChange: Bool
    
    @AppStorage(UserDefaultsKeys.showingBadgesForFoods) var showingBadgesForFoods = PrepConstants.DefaultPreferences.showingBadgesForFoods

    let didDeleteFoodItemFromMeal = NotificationCenter.default.publisher(for: .didDeleteFoodItemFromMeal)
    let swapMealFoodItemPositions = NotificationCenter.default.publisher(for: .swapMealFoodItemPositions)
    let removeMealFoodItemForMove = NotificationCenter.default.publisher(for: .removeMealFoodItemForMove)
    let insertMealFoodItemForMove = NotificationCenter.default.publisher(for: .insertMealFoodItemForMove)

    @Binding var meal: DayMeal
    @State var foodItems: [MealFoodItem]
    @Binding var dragTargetFoodItemId: UUID?
    @ObservedObject var dayViewModel: DayView.ViewModel
    
    @State var shouldShowDropTargetViewForMeal: Bool = false
    
    init(
        date: Date,
        dayViewModel: DayView.ViewModel,
        dragTargetFoodItemId: Binding<UUID?>,
        mealBinding: Binding<DayMeal>,
        isUpcomingMeal: Binding<Bool>,
        isAnimatingItemChange: Binding<Bool>,
        actionHandler: @escaping (LogAction) -> ()
    ) {
        self.dayViewModel = dayViewModel
        _dragTargetFoodItemId = dragTargetFoodItemId
        _meal = mealBinding
        _foodItems = State(initialValue: mealBinding.wrappedValue.foodItems)
        let viewModel = ViewModel(
            date: date,
            meal: mealBinding.wrappedValue,
            isUpcomingMeal: isUpcomingMeal.wrappedValue,
            actionHandler: actionHandler
        )
        _isUpcomingMeal = isUpcomingMeal
        _isAnimatingItemChange = isAnimatingItemChange
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    @State var showingDropOptions: Bool = false
//    @State var droppedFoodItem: MealFoodItem? = nil
    
    var body: some View {
//        mealContent
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
            .onReceive(didDeleteFoodItemFromMeal, perform: didDeleteFoodItemFromMeal)
            .onReceive(swapMealFoodItemPositions, perform: swapMealFoodItemPositions)
            .onReceive(removeMealFoodItemForMove, perform: removeMealFoodItemForMove)
            .onReceive(insertMealFoodItemForMove, perform: insertMealFoodItemForMove)
            .onChange(of: viewModel.isAnimatingItemChange) {
                self.isAnimatingItemChange = $0
            }
            .onChange(of: meal) { newValue in
                viewModel.meal = newValue
                withAnimation {
                    foodItems = newValue.foodItems
                }
            }
            .onChange(of: dragTargetFoodItemId) { newValue in
                viewModel.dragTargetFoodItemId = newValue
            }
            .onChange(of: viewModel.targetId, perform: targetIdChanged)
    }
    
    func targetIdChanged(_ newValue: UUID?) {
        updateShouldShowDropTargetForMeal()
    }
    
    func updateShouldShowDropTargetForMeal() {
        withAnimation(isMovingItem ? .none : .interactiveSpring()) {
            self.shouldShowDropTargetViewForMeal = getShouldShowDropTargetViewForMeal()
        }
    }

    func removeMealFoodItemForMove(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let mealId = userInfo[Notification.Keys.mealId] as? UUID,
              meal.id == mealId,
              let source = userInfo[Notification.Keys.sourceItemPosition] as? Int
        else { return }
        
        print("☎️ Removing \(self.foodItems[source-1].food.name) from: \(source-1) in \(meal.name)")
        
        withAnimation {
            let _ = foodItems.remove(at: source-1)
        }
        
        for i in foodItems.indices {
            foodItems[i].sortPosition = i + 1
        }
    }
    
    func insertMealFoodItemForMove(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let mealId = userInfo[Notification.Keys.mealId] as? UUID,
              meal.id == mealId,
              let foodItem = userInfo[Notification.Keys.foodItem] as? MealFoodItem,
              let target = userInfo[Notification.Keys.targetItemPosition] as? Int
        else { return }
        
        print("☎️ Inserting \(foodItem.food.name) at: \(target) in \(meal.name)")
        
        withAnimation {
            foodItems.insert(foodItem, at: target-1)
        }
        
        for i in foodItems.indices {
            foodItems[i].sortPosition = i + 1
        }
    }

    func swapMealFoodItemPositions(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let mealId = userInfo[Notification.Keys.mealId] as? UUID,
              meal.id == mealId,
              let source = userInfo[Notification.Keys.sourceItemPosition] as? Int,
              let target = userInfo[Notification.Keys.targetItemPosition] as? Int
        else { return }
        
        print("☎️ Swapping \(source-1) and \(target-1) in \(meal.name)")
        withAnimation {
            foodItems.swapAt(source-1, target-1)
        }
        
        for i in foodItems.indices {
            foodItems[i].sortPosition = i + 1
        }
    }
    
    func didDeleteFoodItemFromMeal(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let id = userInfo[Notification.Keys.uuid] as? UUID,
              foodItems.contains(where: { $0.id == id } )
        else { return }

        withAnimation {
            foodItems.removeAll(where: { $0.id == id })
        }
    }
    

    var content: some View {
        var cellsLayer: some View {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 44)
                dropTargetForMeal
                itemRows
                Color.clear
                    .frame(height: 50)
            }
        }
        
        var headerLayer: some View {
            VStack(spacing: 0) {
                header
                Spacer()
            }
        }
        var footerLayer: some View {
            VStack(spacing: 0) {
                Spacer()
                footer
            }
        }
        
        return ZStack {
            cellsLayer
            headerLayer
            footerLayer
        }
    }
    
    var content_latest_legacy: some View {
        ZStack {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 44)
                dropTargetForMeal
                itemRows
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
    
    @ViewBuilder
    var itemRows: some View {
//        ForEach(viewModel.meal.foodItems) { foodItem in
//        ForEach(meal.foodItems) { foodItem in
        ForEach(foodItems) { foodItem in
            if !foodItem.isSoftDeleted {
                cell(for: foodItem)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        )
                    )
//                dropTargetView(for: foodItem)
            }
        }
        if shouldShowEmptyCell {
            Text("Empty")
                .font(.body)
                .fontWeight(.light)
//                .fontWeight(.regular)
                .foregroundColor(Color(.tertiaryLabel))
                .padding(.leading, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .background(
                    Group {
                        colorScheme == .light
                        ? Color(.secondarySystemGroupedBackground)
                        : Color(hex: "232323")
                    }
                        .opacity(colorScheme == .light ? 0.75 : 0.5)
                )
                .transition(.opacity)
        }
    }
    
    var shouldShowEmptyCell: Bool {
        guard foodItems.filter({ !$0.isSoftDeleted }).isEmpty,
              viewModel.targetId == nil else {
            return false
        }
        
        /// If we're showing drop options for the meal header (ie. empty meal), which we
        /// infer by checking if the dropReceipient is nil
        if showingDropOptions, viewModel.dropRecipient == nil {
            return false
        }
        
        return true
    }
    @State var isMovingItem = false
    
    func cell(for mealFoodItem: MealFoodItem) -> some View {
        
        var label: some View {
            let isLastItemOfMealBinding = Binding<Bool>(
                get: { foodItems.last?.id == mealFoodItem.id },
                set: { _ in }
            )
            return Cell(
                item: mealFoodItem,
                showingDropOptions: $showingDropOptions,
                dragTargetFoodItemId: $dragTargetFoodItemId,
                isLastItemOfMeal: isLastItemOfMealBinding,
                isMovingItem: $isMovingItem
            )
            .environmentObject(viewModel)
        }
        
        var button: some View {
            Button {
                viewModel.actionHandler(.editFoodItem(mealFoodItem, viewModel.meal))
            } label: {
                label
            }
        }
        
        @ViewBuilder
        var menuItems: some View {
            Section(mealFoodItem.food.name) {
                Button {
                    viewModel.actionHandler(
                        .editFoodItem(mealFoodItem, viewModel.meal)
                    )
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button {
                    
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
                Divider()
                Button(role: .destructive) {
                    /// Make sure the context menu dismisses first, otherwise the deletion animation glitches
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.actionHandler(
                            .deleteFoodItem(mealFoodItem, viewModel.meal)
                        )
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        
        return button
            .draggable(mealFoodItem) {
                MealView.Cell.DragPreview(item: mealFoodItem)
            }
            .contextMenu(menuItems: { menuItems }, preview: {
                FoodLabel(data: .constant(mealFoodItem.foodLabelData))
            })
    }
    
    var header: some View {
        var shouldShowDropDestination: Bool {
            if !viewModel.isEmpty {
                return true
            }
            
            return false
        }

        return headerView
            .contentShape(Rectangle())
            .if(shouldShowDropDestination, transform: { view in
                view
                    .dropDestination(
                        for: MealFoodItem.self,
                        action: handleDrop,
                        isTargeted: handleDropIsTargeted
                    )
            })
    }
    
    var footer: some View {
        footerView
//        MealView.Footer(meal: meal)
//            .environmentObject(viewModel)
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
        
        updateShouldShowDropTargetForMeal()
    }
    

    var content_legacy: some View {
        ZStack {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 44)
                dropTargetForMeal
                itemRows
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
    
    func shouldShowDropTargetView(for mealFoodItem: MealFoodItem) -> Bool {
        if let id = dragTargetFoodItemId, mealFoodItem.id == id {
            return true
        }
        
        if showingDropOptions,
           let dropRecipient = viewModel.dropRecipient,
           dropRecipient.id == mealFoodItem.id
        {
            return true
        }
        
        return false
    }
    
    @ViewBuilder
    func dropTargetView(for mealFoodItem: MealFoodItem) -> some View {
//        if let id = viewModel.dragTargetFoodItemId,
       if shouldShowDropTargetView(for: mealFoodItem) {
            dropTargetView
                .padding(.top, 12)
                .if(foodItems.last?.id != mealFoodItem.id) {
                    $0.padding(.bottom, 12)
                }
        }
    }

    
    //MARK: - Drag and Drop related
    
    func getShouldShowDropTargetViewForMeal() -> Bool {
        if viewModel.targetId == viewModel.meal.id {
            return true
        }
        
        if showingDropOptions, viewModel.dropRecipient == nil {
            return true
        }
        
        return false
    }
    
    @ViewBuilder
    var dropTargetForMeal: some View {
        if shouldShowDropTargetViewForMeal {
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
            .transition(.opacity)
    }
    
    var dropConfirmationTitle: String {
        guard let droppedFoodItem = viewModel.droppedFoodItem else { return "" }
        return droppedFoodItem.description
    }
    
    @ViewBuilder
    func dropConfirmationActions() -> some View {
        Button("Move") {
            guard let foodItem = viewModel.droppedFoodItem else { return }
            dayViewModel.moveItem(
                foodItem,
                to: viewModel.meal,
                after: viewModel.dropRecipient
            )
            isMovingItem = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isMovingItem = false
            }
//            viewModel.tappedMoveForDrop()
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

extension MealFoodItem {
    var foodLabelData: FoodLabelData {
        FoodLabelData(
            energyValue: FoodLabelValue(amount: scaledValueForEnergyInKcal, unit: .kcal),
            carb: scaledValueForMacro(.carb),
            fat: scaledValueForMacro(.fat),
            protein: scaledValueForMacro(.protein),
            nutrients: microsDictForPreview,
            quantityValue: amount.value,
            quantityUnit: amount.unitDescription(sizes: food.info.sizes)
        )
    }
    
    var microsDictForPreview: [NutrientType : FoodLabelValue] {
        microsDict
            .filter { $0.key.isIncludedInPreview }
    }
}

extension NutrientType {
    var isIncludedInPreview: Bool {
        switch self {
        case .saturatedFat:
            return true
//        case .monounsaturatedFat:
//            return true
//        case .polyunsaturatedFat:
//            return true
        case .transFat:
            return true
        case .cholesterol:
            return true
        case .dietaryFiber:
            return true
//        case .solubleFiber:
//            <#code#>
//        case .insolubleFiber:
//            <#code#>
        case .sugars:
            return true
        case .addedSugars:
            return true
//        case .sugarAlcohols:
//            <#code#>
//        case .calcium:
//            <#code#>
//        case .chloride:
//            <#code#>
//        case .chromium:
//            <#code#>
//        case .copper:
//            <#code#>
//        case .iodine:
//            <#code#>
//        case .iron:
//            <#code#>
//        case .magnesium:
//            return true
//        case .manganese:
//            <#code#>
//        case .molybdenum:
//            <#code#>
//        case .phosphorus:
//            <#code#>
//        case .potassium:
//            return true
//        case .selenium:
//            <#code#>
        case .sodium:
            return true
//        case .zinc:
//            <#code#>
//        case .vitaminA:
//            <#code#>
//        case .vitaminB1_thiamine:
//            <#code#>
//        case .vitaminB2_riboflavin:
//            <#code#>
//        case .vitaminB3_niacin:
//            <#code#>
//        case .vitaminB5_pantothenicAcid:
//            <#code#>
//        case .vitaminB6_pyridoxine:
//            <#code#>
//        case .vitaminB7_biotin:
//            <#code#>
//        case .vitaminB9_folate:
//            <#code#>
//        case .vitaminB9_folicAcid:
//            <#code#>
//        case .vitaminB12_cobalamin:
//            <#code#>
//        case .vitaminC_ascorbicAcid:
//            <#code#>
//        case .vitaminD_calciferol:
//            <#code#>
//        case .vitaminE:
//            <#code#>
//        case .vitaminK1_phylloquinone:
//            <#code#>
//        case .vitaminK2_menaquinone:
//            <#code#>
//        case .choline:
//            <#code#>
//        case .caffeine:
//            <#code#>
//        case .ethanol:
//            <#code#>
//        case .taurine:
//            <#code#>
//        case .polyols:
//            <#code#>
//        case .gluten:
//            <#code#>
//        case .starch:
//            <#code#>
//        case .salt:
//            <#code#>
//        case .creatine:
//            <#code#>
//        case .energyWithoutDietaryFibre:
//            <#code#>
//        case .water:
//            <#code#>
//        case .freeSugars:
//            <#code#>
//        case .ash:
//            <#code#>
//        case .preformedVitaminARetinol:
//            <#code#>
//        case .betaCarotene:
//            <#code#>
//        case .provitaminABetaCaroteneEquivalents:
//            <#code#>
//        case .niacinDerivedEquivalents:
//            <#code#>
//        case .totalFolates:
//            <#code#>
//        case .dietaryFolateEquivalents:
//            <#code#>
//        case .alphaTocopherol:
//            <#code#>
//        case .tryptophan:
//            <#code#>
//        case .linoleicAcid:
//            <#code#>
//        case .alphaLinolenicAcid:
//            <#code#>
//        case .eicosapentaenoicAcid:
//            <#code#>
//        case .docosapentaenoicAcid:
//            <#code#>
//        case .docosahexaenoicAcid:
//            <#code#>
        default:
            return false
        }
    }
}

extension MealView {
    struct DragPreview: View {
        let meal: DayMeal
    }
}

extension MealView.DragPreview {
    var body: some View {
        HStack(spacing: 2) {
            Text(meal.timeString)
                .bold()
                .font(.title2)
            Text("•")
                .font(.title2)
                .foregroundColor(.secondary)
            Text(meal.name)
                .font(.title)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .clippedText()
        .frame(height: 40)
        .frame(width: 200)
        .background(Color(.systemBackground))
        .contentShape([.dragPreview], RoundedRectangle(cornerRadius: 12))
    }
}
