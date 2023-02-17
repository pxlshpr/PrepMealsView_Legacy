import SwiftUI
import SwiftUISugar
import PrepViews
import PrepDataTypes
import PrepCoreDataStack

struct MetricsView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var date: Date

    @State var energy: Double 
    @State var carb: Double
    @State var fat: Double
    @State var protein: Double

    init(date: Binding<Date>) {
        _date = date
        let energy: Double
        let carb: Double
        let fat: Double
        let protein: Double
        if let nutrients = DataManager.shared.nutrients(for: date.wrappedValue) {
            energy = nutrients.energy
            carb = nutrients.carb
            fat = nutrients.fat
            protein = nutrients.protein
        } else {
            energy = 0
            carb = 0
            fat = 0
            protein = 0
        }
        _energy = State(initialValue: energy)
        _carb = State(initialValue: carb)
        _fat = State(initialValue: fat)
        _protein = State(initialValue: protein)
    }
    
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(.systemGroupedBackground)
                VStack {
                    energyRow(proxy)
                    macros(proxy)
                }
            }
            .frame(height: 150)
        }
    }
    
    func energyRow(_ proxy: GeometryProxy) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("\(energy.formattedEnergy) kcal")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
            }
            FoodBadge(c: carb, f: fat, p: protein, width: .constant(proxy.size.width)
            )
        }
    }
    
    func macros(_ proxy: GeometryProxy) -> some View {
        let spacing: CGFloat = 5.0
        
        var macroWidth: CGFloat {
            let width = (proxy.size.width / 3.0) - (3 * 1.0)
            return max(width, 0)
        }
        
        func value(for macro: Macro) -> Double {
            switch macro {
            case .carb:
                return carb
            case .fat:
                return fat
            case .protein:
                return protein
            }
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
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Spacer()
                            Text(value(for: macro).formattedMacro)
                                .font(.system(.title2, design: .rounded, weight: .medium))
                            Text("g")
                                .font(.system(.callout, design: .rounded, weight: .medium))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .frame(width: macroWidth)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemBackground))
                )
            }
        }
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
