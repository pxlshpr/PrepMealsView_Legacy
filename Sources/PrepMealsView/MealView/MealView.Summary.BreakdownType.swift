import Foundation

extension MealView.Summary {
    enum BreakdownType: CaseIterable, CustomStringConvertible {
        case energy
        case carbs
        case fat
        case protein
        
        var description: String {
            switch self {
            case .energy:
                return "Energy"
            case .carbs:
                return "Carbohydrate"
            case .fat:
                return "Fat"
            case .protein:
                return "Protein"
            }
        }
    }
}
