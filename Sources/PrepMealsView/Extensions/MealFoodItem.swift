import Foundation
import PrepDataTypes

extension MealFoodItem {
    var isCompleted: Bool {
        guard let markedAsEatenAt else { return false }
        return markedAsEatenAt > 0
    }
    
    var quantityDescription: String {
        amount.description(with: food)
    }
}
