import SwiftUI
import PrepDataTypes

extension MealView {
    class ViewModel: ObservableObject {
        
        @Published var meal: DayMeal
        @Published var foodItems: [FoodItem]
        
        init(meal: DayMeal) {
            self.meal = meal
            self.foodItems = meal.foodItems
            
            NotificationCenter.default.addObserver(
                self, selector: #selector(didAddFoodItemToMeal),
                name: .didAddFoodItemToMeal, object: nil)
        }
    }
}

extension MealView.ViewModel {
    @objc func didAddFoodItemToMeal(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let foodItem = userInfo[Notification.Keys.foodItem] as? FoodItem
        else {
            return
        }

        /// Make sure this is the `MealView.ViewModel` for the `Meal` that the `FoodItem` belongs to before proceeding
        guard foodItem.meal?.id == meal.id else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                self.foodItems.append(foodItem)
            }
        }
    }
}

extension MealView.ViewModel {
    
    var animationID: String {
        meal.id.uuidString
    }
    
    var headerString: String {
        "**\(meal.timeString)** • \(meal.name)"
    }
    
    var deleteString: String {
        "Delete \(meal.name)"
    }
    
    var shouldShowUpcomingLabel: Bool {
        meal.isNextPlannedMeal
    }
    
    var shouldShowAddFoodActionInMenu: Bool {
        meal.isCompleted
    }
    
    var shouldShowCompleteActionInMenu: Bool {
        !meal.isCompleted
    }
    
    func tappedComplete() {
        //TODO: CoreData
//        Store.shared.toggleCompletionForMeal(meal)
    }
    
    func tappedDelete() {
        //TODO: Rewrite
//        withAnimation {
//            while !foodItems.isEmpty {
//                foodItems.removeLast()
//            }
//        }
//
//        /// We delay the deletion of the meal slightly to allow the foodItems removal animations to complete. This is because they are based on a manually managed array, and the immediate deletion of the meal would result in their `NSManagedObject`s to be deleted before the animation, thus showing empty cells in their place during the meal removal animation
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            Store.removeMealNotification(for: self.meal)
//            Store.updateFastingNotifications()
//            Store.shared.delete(self.meal)
//            NotificationCenter.default.post(name: .updateFastingTimer, object: nil)
//            NotificationCenter.default.post(name: .updateStatsView, object: nil)
////            NotificationCenter.default.post(name: .statsViewShouldShowPlanned, object: nil)
//        }
    }
}
