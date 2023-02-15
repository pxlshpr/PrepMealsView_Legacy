import SwiftUI
import SwiftHaptics
import PrepDataTypes
import SwiftUISugar
import FoodLabel

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
            actionHandler: @escaping (LogAction) -> ()
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
            .draggable(mealFoodItem.wrappedValue)
            .contextMenu(menuItems: {
                Section(mealFoodItem.food.name.wrappedValue) {
                    Button {
                        viewModel.actionHandler(
                            .editFoodItem(mealFoodItem.wrappedValue, viewModel.meal)
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
                        
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }, preview: {
                FoodLabel(data: .constant(mealFoodItem.wrappedValue.foodLabelData))
//                ZStack {
//
//                    Color.blue
//                        .frame(width: 300, height: 1300)
//                }
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
