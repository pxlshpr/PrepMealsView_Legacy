import SwiftUI
import SwiftUISugar
import PrepViews
import PrepDataTypes
import PrepCoreDataStack

struct MetricsView: View {
    
    @Environment(\.colorScheme) var colorScheme

    @AppStorage(UserDefaultsKeys.lastSelectedMetricsTab) var lastSelectedMetricsTab = 1

    @Binding var date: Date
    @State var data: MetricsData
    
    let shouldUpdateMetrics = NotificationCenter.default.publisher(for: .shouldUpdateMetrics)
    let didAddFoodItem = NotificationCenter.default.publisher(for: .didAddFoodItemToMeal)
    let didDeleteFoodItemFromMeal = NotificationCenter.default.publisher(for: .didDeleteFoodItemFromMeal)
    let didUpdateMealFoodItem = NotificationCenter.default.publisher(for: .didUpdateMealFoodItem)
    let didUpdateFoodItems = NotificationCenter.default.publisher(for: .didUpdateFoodItems)
    let didDeleteMeal = NotificationCenter.default.publisher(for: .didDeleteMeal)
    
    init(date: Binding<Date>) {
        _date = date
//        let nutrients: MetricsData
//        if let dayNutrients = DataManager.shared.nutrients(for: date.wrappedValue) {
//            nutrients = dayNutrients
//        } else {
//            nutrients = .zero
//        }
        _data = State(initialValue: .zero)
    }
    
    var body: some View {
        TabView(selection: $lastSelectedMetricsTab) {
            energyAndMacrosPage.tag(1)
            page2.tag(2)
            page3.tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 140)
        .onAppear(perform: appeared)
        .onReceive(shouldUpdateMetrics, perform: update)
        .onReceive(didAddFoodItem, perform: update)
        .onReceive(didDeleteFoodItemFromMeal, perform: update)
        .onReceive(didUpdateMealFoodItem, perform: update)
        .onReceive(didUpdateFoodItems, perform: update)
        .onReceive(didDeleteMeal, perform: update)
    }
    
    
    var energyAndMacrosPage: some View {
        Group {
            GeometryReader { proxy in
                ZStack(alignment: .top) {
                    backgroundColor
                    VStack(spacing: 10) {
                        energyRow(proxy)
                        macros(proxy)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 140)
    }
    
    var page2: some View {
        Text("Page 2")
            .padding(.horizontal, 10)
    }

    var page3: some View {
        Text("Page 3")
            .padding(.horizontal, 10)
    }

    func appeared() {
        loadData(isInitialLoad: true)
    }
    
    func loadData(isInitialLoad: Bool = false) {
        Task {
            let dayNutrients = try await DataManager.shared.metricsData(for: date)
            DispatchQueue.main.asyncAfter(deadline: .now() + (isInitialLoad ? 0.3 : 0)) {
                withAnimation {
                self.data = dayNutrients
                }
            }
        }
    }
    
    func update(_ notification: Notification) {
        loadData()
    }
    
    var backgroundColor: Color {
        colorScheme == .light ? Color(.systemGroupedBackground) : Color(hex: "191919")
//        Color.accentColor
    }
    
    func energyRow(_ proxy: GeometryProxy) -> some View {
        
        var energyView: some View {
            var badge: some View {
                FoodBadge(
                    c: data.carb,
                    f: data.fat,
                    p: data.protein,
                    width: .constant(proxy.size.width)
                )
                .frame(height: 12)
            }
            
            var meter: some View {
                NutrientMeter(viewModel: .init(get: {
                    .init(
                        component: .energy,
                        goalLower: data.energyLower,
                        goalUpper: data.energyUpper,
                        planned: data.energy,
                        eaten: 0
                    )
                }, set: { _ in }))
                .frame(height: 12)
            }
            
            return Group {
//                if data.haveEnergyGoal {
                    meter
//                } else {
//                    badge
//                }
            }
        }
        
        return VStack(spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Color.clear
                    .animatedEnergyValue(value: data.energy)
                Spacer()
                Color.clear
                    .animatedEnergyRemainingValue(value: data.energyRemaining)
            }
            .padding(.horizontal, 10)
            energyView
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
        
        func macroView(for macro: Macro) -> some View {
            
            var goalLower: Double? {
                switch macro {
                case .carb:
                    return data.carbLower
                case .fat:
                    return data.fatLower
                case .protein:
                    return data.proteinLower
                }
            }
            
            var goalUpper: Double? {
                switch macro {
                case .carb:
                    return data.carbUpper
                case .fat:
                    return data.fatUpper
                case .protein:
                    return data.proteinUpper
                }
            }
            
            var value: Double {
                switch macro {
                case .carb:
                    return data.carb
                case .fat:
                    return data.fat
                case .protein:
                    return data.protein
                }
            }

            var meterView: some View {
                NutrientMeter(viewModel: .init(get: {
                    .init(
                        component: macro.nutrientMeterComponent,
                        goalLower: goalLower,
                        goalUpper: goalUpper,
                        planned: value,
                        eaten: 0
                    )
                }, set: { _ in }))
                .frame(height: 7)
                .padding(.top, 5)
                .padding(.bottom, 1)
            }
            
            var meterOpacity: CGFloat {
                data.haveGoal(for: macro) ? 1 : 0
            }
            
            return VStack(spacing: 0) {
                HStack {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(macro.fillColor(for: colorScheme).gradient)
                        .frame(width: 10, height: 10)
                    Text(macro.abbreviatedDescription)
                        .font(.system(.footnote, design: .rounded, weight: .regular))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                meterView
                    .opacity(meterOpacity)
                HStack {
                    Spacer()
                    Color.clear
                        .animatedMacroValue(value: data.value(for: macro))
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
        
        return HStack(spacing: spacing) {
            ForEach(Macro.allCases, id: \.self) { macro in
                macroView(for: macro)
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

struct AnimatableEnergyRemainingValue: AnimatableModifier {
    
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
                .font(.system(.headline, design: .rounded, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))
            Text("kcal")
                .font(.system(.body, design: .rounded, weight: .regular))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: true, vertical: false)
    }
}

extension View {
    func animatedEnergyRemainingValue(value: Double) -> some View {
        modifier(AnimatableEnergyRemainingValue(value: value))
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
