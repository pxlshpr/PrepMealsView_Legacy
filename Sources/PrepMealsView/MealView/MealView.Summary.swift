import SwiftUI
//import Charts
import PrepDataTypes
import SwiftHaptics

extension MealView {
    struct Summary: View {
        //TODO: CoreData
//        @ObservedObject var meal: Meal
        var meal: Meal
        @State var breakdownType: BreakdownType = .energy
        
        //TODO: Rename this if we're still using it
        @State var total: Int
        
        @State private var selectedFoodItem: [FoodItem] = []
        
        @State private var embeddedInNavigationStack: Bool
        
        //TODO: Remove this if we're not using total anymore
        init(meal: Meal, embeddedInNavigationStack: Bool = false) {
            //TODO: CoreData
//            _meal = ObservedObject(initialValue: meal)
            self.meal = meal
            _total = State(initialValue: Int(meal.energyAmount))
            _embeddedInNavigationStack = State(initialValue: embeddedInNavigationStack)
        }
    }
}

extension MealView.Summary {
    
    var body: some View {
        Group {
            if embeddedInNavigationStack {
                NavigationStack(path: $selectedFoodItem) {
                    content
                }
            } else {
                content
            }
        }
    }
    
    var content: some View {
        scrollView
            .navigationTitle(meal.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: FoodItem.self) { foodItem in
                Text("Charts for \(foodItem.food.name)")
            }
    }
    
    var scrollView: some View {
        ScrollView {
            VStack {
                foodBreakdown
                Spacer().frame(height: 30)
                Divider()
                Spacer().frame(height: 30)
                macroBreakdown
            }
            .padding()
        }
    }
    
    var macroBreakdown: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Text("Macro With Most Calories")
                    .foregroundStyle(.secondary)
            }
//            HStack {
//                Text(meal.largestMacro?.macro.description ?? "")
//                    .font(.title2.bold())
//                Text("\(Int(meal.largestMacro?.grams ?? 0.0)) g")
//                    .font(.title3)
//                    .foregroundColor(Color(.tertiaryLabel))
//            }
            Spacer().frame(height: 10)
            macroBreakdownChart
        }
    }
    var foodBreakdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("Food With Most")
                    .foregroundStyle(.secondary)
                breakdownMenu
            }
            Text(sortedItems.first?.food.name ?? "")
                .font(.title2.bold())
                .offset(y: -10)
            Spacer().frame(height: 10)
            foodBreakdownChart
        }
    }
    
    var breakdownMenu: some View {
        Menu {
            Section {
                Button("Energy") { }
                Button("Carbohydrate") { }
                Button("Fat") { }
                Button("Protein") { }
            }
            Section {
                ForEach(NutrientTypeGroup.allCases, id: \.self) { group in
                    Menu {
                        Button("Micros go here") {
                            
                        }
                    } label: {
                        Text(group.description)
                    }
                }
            }
        } label: {
            Text("Energy")
            Image(systemName: "chevron.up.chevron.down")
        }
        .padding(.bottom, 15)
    }
    
    var sortedItems: [FoodItem] {
        meal.foodItems.sorted(by: { $0.energyAmount > $1.energyAmount })
    }
    
    
    //TODO: Bring back with Charts
    var macroBreakdownChart: some View {
        Color.cyan
//        Chart {
//            ForEach(meal.macrosData.macros, id: \.self.macro.description) { macro in
//                Plot {
//                    BarMark(
//                        x: .value("Data Size", macro.kcal),
//                        y: .value("Macro", macro.macro.description),
//                        width: 20
//                    )
//                    .foregroundStyle(by: .value("Data Category", macro.macro.chartComponent.rawValue))
//                }
//            }
//        }
//        .chartForegroundStyleScale([
//            ChartComponent.carb.rawValue : Macro.carb.color.gradient,
//            ChartComponent.fat.rawValue : Macro.fat.color.gradient,
//            ChartComponent.protein.rawValue : Macro.protein.color.gradient
//        ])
//        .chartPlotStyle { plotArea in
//            plotArea
//                .background(Color(.quaternarySystemFill))
//                .frame(maxWidth: .infinity)
//                .frame(height: CGFloat(3 * 45))
//        }
//        .chartXScale(domain: 0...((meal.largestMacro?.kcal ?? 0) + 50))
//        .chartLegend(.visible)
//        .chartXAxis {
//            AxisMarks(preset: .automatic, values: .automatic(desiredCount: 3)) { value in
//                if let intValue = value.as(Int.self) {
//                    if intValue == 0 {
//                        AxisTick(stroke: .init(lineWidth: 1))
//                            .foregroundStyle(.gray)
//                        AxisValueLabel() {
//                            Text("\(intValue) kcal")
//                        }
//                        AxisGridLine(stroke: .init(lineWidth: 1))
//                            .foregroundStyle(.gray)
//                    } else if intValue % 2 == 0 {
//                        AxisTick(stroke: .init(lineWidth: 0.25))
//                            .foregroundStyle(.gray)
//                        AxisValueLabel() {
//                            Text("\(intValue)")
//                        }
//                        AxisGridLine(stroke: .init(lineWidth: 0.25, dash: [4.0, 3.0]))
//                            .foregroundStyle(.gray)
//                    } else {
//                        AxisTick(stroke: .init(lineWidth: 1))
//                            .foregroundStyle(.gray.opacity(0.25))
//                        AxisGridLine(stroke: .init(lineWidth: 1))
//                            .foregroundStyle(.gray.opacity(0.25))
//                    }
//                }
//            }
//        }
    }
    
//    func findFoodItem(location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> FoodItem? {
////        let relativeXPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
////        if let date = proxy.value(atX: relativeXPosition) as Date? {
////            // Find the closest date element.
////            var minDistance: TimeInterval = .infinity
////            var index: Int? = nil
////            for salesDataIndex in SalesData.last30Days.indices {
////                let nthSalesDataDistance = SalesData.last30Days[salesDataIndex].day.distance(to: date)
////                if abs(nthSalesDataDistance) < minDistance {
////                    minDistance = abs(nthSalesDataDistance)
////                    index = salesDataIndex
////                }
////            }
////            if let index = index {
////                return SalesData.last30Days[index]
////            }
////        }
//
//        let relativeYPosition = location.y - geometry[proxy.plotAreaFrame].origin.y
//        if let stringValue = proxy.value(atY: relativeYPosition) as String? {
//            for item in meal.itemsArray {
//                if item.plottable.primitivePlottable == stringValue {
//                    return item
//                }
//            }
//        }
//
//        return nil
//    }
    
    var foodBreakdownChart: some View {
        Color.cyan
//        Chart {
//            ForEach(sortedItems, id: \.self.id) { item in
//                ForEach(item.macrosData.macros, id: \.self.macro.description) { element in
//                    Plot {
//                        BarMark(
//                            x: .value("Data Size", element.kcal),
//                            y: .value("Food", item.plottable),
////                            y: .value("Food", "\(item.emojiString ?? "")\(item.emojiString == nil ? "" : " ")\(item.nameString)"),
//                            width: 20
//                        )
//                        .foregroundStyle(by: .value("Data Category", element.macro.chartComponent.rawValue))
//                    }
//                }
//            }
//        }
//        .chartForegroundStyleScale([
//            ChartComponent.carb.rawValue : Macro.carb.color.gradient,
//            ChartComponent.fat.rawValue : Macro.fat.color.gradient,
//            ChartComponent.protein.rawValue : Macro.protein.color.gradient
//        ])
//        .chartPlotStyle { plotArea in
//            plotArea
//                .background(Color(.quaternarySystemFill))
//                .frame(maxWidth: .infinity)
//                .frame(height: CGFloat(meal.itemsArray.count * 45))
//        }
//        .chartXScale(domain: 0...meal.largestItemEnergy)
//        .chartLegend(.visible)
//        .chartXAxis {
//            AxisMarks(preset: .automatic, values: .automatic(desiredCount: 3)) { value in
//                if let intValue = value.as(Int.self) {
//                    if intValue == 0 {
//                        AxisTick(stroke: .init(lineWidth: 1))
//                            .foregroundStyle(.gray)
//                        AxisValueLabel() {
//                            Text("\(intValue) kcal")
//                        }
//                        AxisGridLine(stroke: .init(lineWidth: 1))
//                            .foregroundStyle(.gray)
//                    } else if intValue % 2 == 0 {
//                        AxisTick(stroke: .init(lineWidth: 0.25))
//                            .foregroundStyle(.gray)
//                        AxisValueLabel() {
//                            Text("\(intValue)")
//                        }
//                        AxisGridLine(stroke: .init(lineWidth: 0.25, dash: [4.0, 3.0]))
//                            .foregroundStyle(.gray)
//                    } else {
//                        AxisTick(stroke: .init(lineWidth: 1))
//                            .foregroundStyle(.gray.opacity(0.25))
//                        AxisGridLine(stroke: .init(lineWidth: 1))
//                            .foregroundStyle(.gray.opacity(0.25))
//                    }
//                }
//            }
//        }
//        .chartOverlay { proxy in
//            GeometryReader { nthGeometryItem in
//                Rectangle().fill(.clear).contentShape(Rectangle())
//                    .gesture(
//                        SpatialTapGesture()
//                            .onEnded { value in
//                                selectedFoodItem(findFoodItem(location: value.location, proxy: proxy, geometry: nthGeometryItem))
//                            }
//                            .exclusively(
//                                before: DragGesture()
//                                    .onChanged { value in
//                                        selectedFoodItem(findFoodItem(location: value.location, proxy: proxy, geometry: nthGeometryItem))
//                                    }
//                            )
//                    )
//            }
//        }
    }
    
    func selectedFoodItem(_ foodItem: FoodItem?) {
        guard let foodItem = foodItem else { return }
        Haptics.feedback(style: .rigid)
        selectedFoodItem = [foodItem]
    }
}

//MARK: - Sort these

//TODO: Consolidate this with values in NutritionLabelClassifier

let FatCals = 8.75428571
let CarbCals = 4.0
let ProteinCals = 4.0

//extension Meal {
//    //TODO: Modularize repeated code between FoodItem, Meal, and Day for macrosData and its constituents
//    var macrosData: MacrosData {
//        MacrosData(macros: [
//            MacrosData.MacroData(macro: .carb, kcal: carbCalories),
//            MacrosData.MacroData(macro: .fat, kcal: fatCalories),
//            MacrosData.MacroData(macro: .protein, kcal: proteinCalories),
//        ])
//    }
//
////    var macrosData: MacrosData {
////        MacrosData(macros: [
////            MacrosData.MacroData(macro: .carb, kcal: carbAmount * 4),
////            MacrosData.MacroData(macro: .fat, kcal: fatAmount * 9),
////            MacrosData.MacroData(macro: .protein, kcal: proteinAmount * 4),
////        ])
////    }
//
//    var largestItemEnergy: Int {
//        Int(itemsArray.sorted(by: { $0.energyAmount > $1.energyAmount }).first?.energyAmount ?? 0)
////        itemsArray.max(by: { $0.energyAmount > $1.energyAmount })?.energyAmount ?? 0
//    }
//
//    //TODO: Make this a function on MacrosData
//    var largestMacro: MacrosData.MacroData? {
//        macrosData.macros.sorted(by: { $0.kcal > $1.kcal }).first
//    }
//
//    var carbCalories: Double {
//        energyAmount * carbEnergyPercentage
//    }
//
//    var fatCalories: Double {
//        energyAmount * fatEnergyPercentage
//    }
//
//    var proteinCalories: Double {
//        energyAmount * proteinEnergyPercentage
//    }
//
//    var carbEnergyPercentage: Double {
//        guard carbAmount > 0 else { return 0 }
//        if fatAmount > 0 {
//            if proteinAmount > 0 {
//                return CarbCals/(CarbCals + FatCals + ProteinCals)
//            } else {
//                return CarbCals/(CarbCals + FatCals)
//            }
//        } else if proteinAmount > 0 {
//            return CarbCals/(CarbCals + ProteinCals)
//        } else {
//            return 1.0
//        }
//    }
//
//    var fatEnergyPercentage: Double {
//        guard fatAmount > 0 else { return 0 }
//        if carbAmount > 0 {
//            if proteinAmount > 0 {
//                return FatCals/(FatCals + CarbCals + ProteinCals)
//            } else {
//                return FatCals/(FatCals + CarbCals)
//            }
//        } else if proteinAmount > 0 {
//            return FatCals/(FatCals + ProteinCals)
//        } else {
//            return 1.0
//        }
//    }
//
//    var proteinEnergyPercentage: Double {
//        guard proteinAmount > 0 else { return 0 }
//        if carbAmount > 0 {
//            if fatAmount > 0 {
//                return ProteinCals/(ProteinCals + CarbCals + FatCals)
//            } else {
//                return ProteinCals/(ProteinCals + CarbCals)
//            }
//        } else if fatAmount > 0 {
//            return ProteinCals/(ProteinCals + FatCals)
//        } else {
//            return 1.0
//        }
//    }
//}
//
//extension FoodItem {
//
//    var carbCalories: Double {
//        energyAmount * carbEnergyPercentage
//    }
//
//    var fatCalories: Double {
//        energyAmount * fatEnergyPercentage
//    }
//
//    var proteinCalories: Double {
//        energyAmount * proteinEnergyPercentage
//    }
//
//    var carbEnergyPercentage: Double {
//        guard carbAmount > 0 else { return 0 }
//        if fatAmount > 0 {
//            if proteinAmount > 0 {
//                return CarbCals/(CarbCals + FatCals + ProteinCals)
//            } else {
//                return CarbCals/(CarbCals + FatCals)
//            }
//        } else if proteinAmount > 0 {
//            return CarbCals/(CarbCals + ProteinCals)
//        } else {
//            return 1.0
//        }
//    }
//
//    var fatEnergyPercentage: Double {
//        guard fatAmount > 0 else { return 0 }
//        if carbAmount > 0 {
//            if proteinAmount > 0 {
//                return FatCals/(FatCals + CarbCals + ProteinCals)
//            } else {
//                return FatCals/(FatCals + CarbCals)
//            }
//        } else if proteinAmount > 0 {
//            return FatCals/(FatCals + ProteinCals)
//        } else {
//            return 1.0
//        }
//    }
//
//    var proteinEnergyPercentage: Double {
//        guard proteinAmount > 0 else { return 0 }
//        if carbAmount > 0 {
//            if fatAmount > 0 {
//                return ProteinCals/(ProteinCals + CarbCals + FatCals)
//            } else {
//                return ProteinCals/(ProteinCals + CarbCals)
//            }
//        } else if fatAmount > 0 {
//            return ProteinCals/(ProteinCals + FatCals)
//        } else {
//            return 1.0
//        }
//    }
//
//    var macrosData: MacrosData {
//        MacrosData(macros: [
//            MacrosData.MacroData(macro: .carb, kcal: carbCalories),
//            MacrosData.MacroData(macro: .fat, kcal: fatCalories),
//            MacrosData.MacroData(macro: .protein, kcal: proteinCalories),
//        ])
//    }
//}
//
//extension Day {
//    var energy: Double {
//        mealsArray.reduce(0) { $0 + $1.energyAmount }
//    }
//}
//

//TODO: Bring back with Charts
//extension FoodItem {
//    var plottable: PlottableFoodItem {
//        PlottableFoodItem(foodItem: self)
//    }
//}

//struct PlottableFoodItem: Plottable {
//
//    var foodItem: FoodItem
//    var primitivePlottable: String
//
//    init?(primitivePlottable: String) {
//        print("📐 Couldn't get a PlottableFoodItem from : \(primitivePlottable)")
//        return nil
////        self.primitivePlottable = primitivePlottable
//    }
//
//    init(foodItem: FoodItem) {
//        self.foodItem = foodItem
//
////        self.primitivePlottable = "\(foodItem.emojiString ?? "")\(foodItem.emojiString == nil ? "" : " ")\(foodItem.nameString)"
//        self.primitivePlottable = "\(foodItem.emojiString ?? "")\(foodItem.emojiString == nil ? "" : " ")\(foodItem.nameString) • \(foodItem.amountString(withDetails: false, parentMultiplier: 1))"
//    }
//
//    typealias PrimitivePlottable = String
//}
