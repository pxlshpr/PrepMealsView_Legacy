import SwiftUI
import PrepDataTypes

extension Array where Element == DayMeal {
    
    mutating func addFoodItem(_ foodItem: FoodItem) {
        guard let mealIndex = firstIndex(where: { $0.id == foodItem.meal?.id }) else {
            return
        }
        self[mealIndex].foodItems.append(MealFoodItem(from: foodItem))
    }
    
    mutating func updateFoodItem(_ foodItem: FoodItem) {
        guard let mealIndex = firstIndex(where: { $0.id == foodItem.meal?.id }),
              let foodItemIndex = self[mealIndex].foodItems.firstIndex(where: { $0.id == foodItem.id })
        else {
            return
        }
        self[mealIndex].foodItems[foodItemIndex] = MealFoodItem(from: foodItem)
    }
    
    mutating func deleteFoodItem(with id: UUID) {
        var mealIndex: Int? = nil
        var f: Int? = nil
        for i in indices {
            if let foodItemIndex = self[i].foodItems.firstIndex(where: { $0.id == id }) {
                mealIndex = i
                f = foodItemIndex
            }
        }
        guard let mealIndex, let f else { return }
        self[mealIndex].foodItems.remove(at: f)
    }

}

extension Array where Element == DayMeal {
    var nextPlannedMeal: DayMeal? {
        self
            .filter { Date().timeIntervalSince($0.timeDate) < 0 }
            .sorted(by: { Date().timeIntervalSince($0.timeDate) > Date().timeIntervalSince($1.timeDate) })
            .first
    }
}
