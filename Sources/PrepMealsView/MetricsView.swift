import SwiftUI
import SwiftUISugar
import PrepViews
import PrepDataTypes
import PrepCoreDataStack

struct MetricsView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var date: Date
    
    @State var nutrients: DayNutrients
    
    let shouldUpdateMetrics = NotificationCenter.default.publisher(for: .shouldUpdateMetrics)
    let didAddFoodItem = NotificationCenter.default.publisher(for: .didAddFoodItemToMeal)
    let didDeleteFoodItemFromMeal = NotificationCenter.default.publisher(for: .didDeleteFoodItemFromMeal)
    let didUpdateMealFoodItem = NotificationCenter.default.publisher(for: .didUpdateMealFoodItem)
    let didUpdateFoodItems = NotificationCenter.default.publisher(for: .didUpdateFoodItems)
    let didDeleteMeal = NotificationCenter.default.publisher(for: .didDeleteMeal)
    
    init(date: Binding<Date>) {
        _date = date
//        let nutrients: DayNutrients
//        if let dayNutrients = DataManager.shared.nutrients(for: date.wrappedValue) {
//            nutrients = dayNutrients
//        } else {
//            nutrients = .zero
//        }
        _nutrients = State(initialValue: .zero)
    }
    
    
    var body: some View {
        Group {
            GeometryReader { proxy in
                ZStack {
                    backgroundColor
                    VStack {
                        energyRow(proxy)
                        macros(proxy)
                    }
                }
            }
        }
        .frame(height: 150)
        .onAppear(perform: loadData)
        .onReceive(shouldUpdateMetrics, perform: update)
        .onReceive(didAddFoodItem, perform: update)
        .onReceive(didDeleteFoodItemFromMeal, perform: update)
        .onReceive(didUpdateMealFoodItem, perform: update)
        .onReceive(didUpdateFoodItems, perform: update)
        .onReceive(didDeleteMeal, perform: update)
    }
    
    func loadData() {
        Task {
            let dayNutrients = try await DataManager.shared.nutrients(for: date)
            withAnimation {
                self.nutrients = dayNutrients
            }
        }
    }
    
    func update(_ notification: Notification) {
        loadData()
    }
    
    var backgroundColor: Color {
        colorScheme == .light ? Color(.systemGroupedBackground) : Color(hex: "191919")
    }
    
    func energyRow(_ proxy: GeometryProxy) -> some View {
        VStack(spacing: 4) {
            HStack {
                Color.clear
                    .animatedEnergyValue(value: nutrients.energy)
//                Text("\(nutrients.energy.formattedEnergy) kcal")
//                    .font(.system(.title3, design: .rounded, weight: .semibold))
            }
            FoodBadge(
                c: nutrients.carb,
                f: nutrients.fat,
                p: nutrients.protein,
                width: .constant(proxy.size.width)
            )
        }
    }
    
    func macros(_ proxy: GeometryProxy) -> some View {
        let spacing: CGFloat = 5.0
        
        var macroWidth: CGFloat {
            let width = (proxy.size.width / 3.0) - (3 * 1.0)
            return max(width, 0)
        }
        
        var backgroundColor: Color {
            colorScheme == .light ? .white : Color(hex: "232323")
            //            Color(.tertiarySystemBackground)
        }
        
        return HStack(spacing: spacing) {
            ForEach(Macro.allCases, id: \.self) { macro in
                VStack {
                    HStack {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(macro.fillColor(for: colorScheme).gradient)
                            .frame(width: 10, height: 10)
                        Text(macro.abbreviatedDescription)
                            .font(.system(.footnote, design: .rounded, weight: .regular))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Color.clear
                            .animatedMacroValue(value: nutrients.value(for: macro))
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .frame(width: macroWidth)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(backgroundColor)
                )
            }
        }
    }
}

struct AnimatableMacroValue: AnimatableModifier {
    
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
            Text(value.formattedMacro)
                .font(.system(.title2, design: .rounded, weight: .medium))
            Text("g")
                .font(.system(.callout, design: .rounded, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: true, vertical: false)
    }
}

extension View {
    func animatedMacroValue(value: Double) -> some View {
        modifier(AnimatableMacroValue(value: value))
    }
}

struct AnimatableEnergyValue: AnimatableModifier {
    
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
                .font(.system(.title, design: .rounded, weight: .semibold))
            Text("kcal")
                .font(.system(.title3, design: .rounded, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: true, vertical: false)
    }
}

extension View {
    func animatedEnergyValue(value: Double) -> some View {
        modifier(AnimatableEnergyValue(value: value))
    }
}
extension Macro {
    var abbreviatedDescription: String {
        switch self {
        case .carb:
            return "Carbs"
        case .fat:
            return "Fats"
        case .protein:
            return "Protein"
        }
    }
}
