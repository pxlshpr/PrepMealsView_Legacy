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
    
    @State var items: [MealFoodItem] = []
    
    let didDeleteFoodItemFromMeal = NotificationCenter.default.publisher(for: .didDeleteFoodItemFromMeal)
    
    @Binding var meal: DayMeal
    
    init(
        date: Date,
        mealBinding: Binding<DayMeal>,
        isUpcomingMeal: Binding<Bool>,
        isAnimatingItemChange: Binding<Bool>,
        actionHandler: @escaping (LogAction) -> ()
    ) {
        _meal = mealBinding
        let viewModel = ViewModel(
            date: date,
            meal: mealBinding.wrappedValue,
            isUpcomingMeal: isUpcomingMeal.wrappedValue,
            actionHandler: actionHandler
        )
        _isUpcomingMeal = isUpcomingMeal
        _isAnimatingItemChange = isAnimatingItemChange
        _viewModel = StateObject(wrappedValue: viewModel)
        _items = State(initialValue: meal.foodItems)
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
            .onChange(of: viewModel.isAnimatingItemChange) {
                self.isAnimatingItemChange = $0
            }
            .onChange(of: meal) { newValue in
                viewModel.meal = newValue
            }
    }
    
    func didDeleteFoodItemFromMeal(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let id = userInfo[Notification.Keys.uuid] as? UUID,
              items.contains(where: { $0.id == id })
        else { return }

        withAnimation {
            items.removeAll(where: { $0.id == id })
        }
    }
    

    var content: some View {
        var cellsLayer: some View {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 44)
                dropTargetForMeal
                mealContent
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
    
    @ViewBuilder
    var mealContent: some View {
        itemRows
    }

    var itemRows: some View {
//        ForEach(viewModel.meal.foodItems) { foodItem in
        ForEach(meal.foodItems) { foodItem in
            if !foodItem.isSoftDeleted {
                cell(for: foodItem)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        )
                    )
                dropTargetView(for: foodItem)
            }
        }
    }

//    var itemRowsWithBinding: some View {
//        ForEach(viewModel.meal.foodItems.indices, id: \.self) { index in
//            cell(for: $viewModel.meal.foodItems[index], index: index)
//            dropTargetView(for: viewModel.meal.foodItems[index])
//        }
//    }
    
    func cell(for mealFoodItem: MealFoodItem) -> some View {
        
        var label: some View {
            Cell(item: mealFoodItem)
//                .opacity(0.5)
                .environmentObject(viewModel)
        }
        
        var button: some View {
            Button {
                viewModel.actionHandler(.editFoodItem(mealFoodItem, viewModel.meal))
            } label: {
                label
            }
        }
        
        var labelWithTapGesture: some View {
            label
                .onTapGesture {
                    viewModel.actionHandler(.editFoodItem(mealFoodItem, viewModel.meal))
                }
        }
        
//        return button
        return labelWithTapGesture
        .draggable(mealFoodItem)
        .contextMenu(menuItems: {
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
        }, preview: {
            FoodLabel(data: .constant(mealFoodItem.foodLabelData))
        })
    }

//    var itemRows: some View {
//        ForEach(viewModel.meal.foodItems.indices, id: \.self) { index in
//            cell(for: $viewModel.meal.foodItems[index], index: index)
//                .transition(.asymmetric(insertion: .move(edge: .top), removal: .scale))
//            dropTargetView(for: viewModel.meal.foodItems[index])
//        }
//    }
    
    var header: some View {
        MealView.Header()
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
        MealView.Footer()
            .environmentObject(viewModel)
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
    
//    func cell(for mealFoodItem: Binding<MealFoodItem>, index: Int) -> some View {
//
//        let badgeWidthBinding = Binding<CGFloat>(
//            get: {
//                badgeWidths[mealFoodItem.id] ?? 0
//            },
//            set: { _ in }
//        )
//
//        var label: some View {
//            var yellow: some View {
//                ZStack {
//                    Color.yellow
//                    Text(viewModel.meal.foodItems[index].food.name)
//                }
//                .frame(height: 40)
//            }
//            var mealItemCell: some View {
//                MealItemCell(
//                    item: mealFoodItem,
//                    index: index,
//                    badgeWidth: badgeWidthBinding
//                )
//                .environmentObject(viewModel)
//            }
//
////            return yellow
//            return mealItemCell
//        }
//
//        var button: some View {
//            Button {
//                viewModel.actionHandler(.editFoodItem(mealFoodItem.wrappedValue, viewModel.meal))
//    //            viewModel.didTapMealFoodItem(mealFoodItem, viewModel.meal)
//            } label: {
//                label
//            }
//        }
//
//
//        var asLabel: some View {
//            label
//                .onTapGesture {
//                    viewModel.actionHandler(.editFoodItem(mealFoodItem.wrappedValue, viewModel.meal))
//                }
//        }
//
//        return button
////        return asLabel
//            .draggable(mealFoodItem.wrappedValue)
//            .contextMenu(menuItems: {
//                Section(mealFoodItem.food.name.wrappedValue) {
//                    Button {
//                        viewModel.actionHandler(
//                            .editFoodItem(mealFoodItem.wrappedValue, viewModel.meal)
//                        )
//                    } label: {
//                        Label("Edit", systemImage: "pencil")
//                    }
//                    Button {
//
//                    } label: {
//                        Label("Duplicate", systemImage: "plus.square.on.square")
//                    }
//                    Divider()
//                    Button(role: .destructive) {
//                        viewModel.actionHandler(
//                            .deleteFoodItem(mealFoodItem.wrappedValue, viewModel.meal)
//                        )
//                    } label: {
//                        Label("Delete", systemImage: "trash")
//                    }
//                }
//            }, preview: {
//                FoodLabel(data: .constant(mealFoodItem.wrappedValue.foodLabelData))
////                ZStack {
////
////                    Color.blue
////                        .frame(width: 300, height: 1300)
////                }
////                VStack(alignment: .leading) {
////                    HStack {
////                        Text(mealFoodItem.wrappedValue.food.emoji)
////                        Text(mealFoodItem.wrappedValue.food.name)
////                    }
////                    if let detail = mealFoodItem.wrappedValue.food.detail {
////                        Text(detail)
////                    }
////                    if let brand = mealFoodItem.wrappedValue.food.brand {
////                        Text(brand)
////                    }
////                }
//            })
//        .transition(
//            .asymmetric(
//                insertion: .move(edge: .top),
//                removal: .scale
//            )
//        )
//    }
    
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
