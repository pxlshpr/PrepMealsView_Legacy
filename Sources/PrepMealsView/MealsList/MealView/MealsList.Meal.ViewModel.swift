import SwiftUI
import PrepDataTypes
import PrepCoreDataStack

extension MealsList.Meal {
    class ViewModel: ObservableObject {
        
        @Published var meal: DayMeal
        
        @Published var dragTargetFoodItemId: UUID? = nil
        
        @Published var droppedFoodItem: MealFoodItem? = nil
        @Published var dropRecipient: MealFoodItem? = nil

        @Published var targetId: UUID? = nil

        init(meal: DayMeal) {
            self.meal = meal
            
            NotificationCenter.default.addObserver(
                self, selector: #selector(didAddFoodItemToMeal),
                name: .didAddFoodItemToMeal, object: nil)

            NotificationCenter.default.addObserver(
                self, selector: #selector(didUpdateMealFoodItem),
                name: .didUpdateMealFoodItem, object: nil)

            NotificationCenter.default.addObserver(
                self, selector: #selector(didDeleteFoodItemFromMeal),
                name: .didDeleteFoodItemFromMeal, object: nil)
        }
    }
}

extension MealsList.Meal.ViewModel {
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
        
        let mealFoodItem = MealFoodItem(from: foodItem)
        print("Adding foodItem with animation, place it at: \(foodItem.sortPosition)")
        withAnimation(.interactiveSpring()) {
//            guard foodItem.sortPosition < meal.foodItems.count else {
//                self.meal.foodItems.append(mealFoodItem)
//                return
//            }
            self.meal.foodItems.append(mealFoodItem)

            //TODO: Try simply appending it and then re-sorting it for that item
            // It should take the sort position, insert it correctly, and then reset all the numbers
            /// Re-sort the `foodItems` in case we moved an item within a meal
            resetSortPositions(aroundFoodItemWithId: foodItem.id)
        }
    }
    
    @objc func didUpdateMealFoodItem(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let updatedFoodItem = userInfo[Notification.Keys.foodItem] as? FoodItem
        else {
            return
        }

        /// Make sure this is the `MealView.ViewModel` for the `Meal` that the `FoodItem` belongs to before proceeding
        guard
            updatedFoodItem.meal?.id == meal.id,
            let existingIndex = meal.foodItems.firstIndex(where: { $0.id == updatedFoodItem.id })
        else {
            return
        }
        
        withAnimation(.interactiveSpring()) {
            /// Replace the existing `MealFoodItem` with the updated one
            self.meal.foodItems[existingIndex] = MealFoodItem(from: updatedFoodItem)
            
            /// Re-sort the `foodItems` in case we moved an item within a meal
            resetSortPositions(aroundFoodItemWithId: updatedFoodItem.id)
        }
    }
    
    func resetSortPositions(aroundFoodItemWithId id: UUID?) {
        let before = self.meal.foodItems
        
        self.meal.foodItems.resetSortPositions(aroundFoodItemWithId: id)
        self.meal.foodItems.sort { $0.sortPosition < $1.sortPosition }
        
        //TODO: ⚠️ **** CRUCIAL ****
        /// We now (or after calling this), need to
        /// [x] Update any of the `FoodItem`'s that have had their `sortPosition` changed with the backend,
        /// [x] modifying the `updatedAt` flags, and
        /// [x] reseting the `syncStatus`.
        for oldItem in before {
            guard let newItem = self.meal.foodItems.first(where: { $0.id == oldItem.id }) else {
                /// We shouldn't get here
                continue
            }
            if newItem.sortPosition != oldItem.sortPosition {
                do {
                    try DataManager.shared.silentlyUpdateSortPosition(for: newItem)
                } catch {
                    print("Error updating sort position: \(error)")
                }
            }
        }
    }
    
    @objc func didDeleteFoodItemFromMeal(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let id = userInfo[Notification.Keys.uuid] as? UUID,
              meal.foodItems.contains(where: { $0.id == id })
        else {
            return
        }

        withAnimation(.interactiveSpring()) {
            self.meal.foodItems.removeAll(where: { $0.id == id })
            resetSortPositions(aroundFoodItemWithId: nil)
        }
    }
}

import PrepDataTypes

extension Array where Element == MealFoodItem {
    
    var hasValidSortPositions: Bool {
        for i in self.indices {
            guard self[i].sortPosition == i + 1 else {
                return false
            }
        }
        return true
    }
    
    mutating func resetSortPositions(aroundFoodItemWithId id: UUID?) {
        
        /// Don't continue if the sort positions are valid
        guard !hasValidSortPositions else {
            return
        }
        
        if let id {
            /// First get the index and remove the `foodItem`
            guard let currentIndex = self.firstIndex(where: { $0.id == id }) else {
                return
            }
            let removed = self.remove(at: currentIndex)
            
            //TODO: ⚠️ **** CRUCIAL ****
            /// [ ] Have a failsafe that makes sure we don't insert this out of range (or with a negative index)

            /// Now insert it where it actually belongs
            self.insert(removed, at: removed.sortPosition - 1)
        }
        
        /// Finally, renumber all the items for the array just to be safe (can be optimised later)
        for i in self.indices {
            self[i].sortPosition = i + 1
        }
    }
}


extension MealsList.Meal.ViewModel {
    
    var targetingDropOverHeader: Bool {
        targetId == meal.id
    }
    var animationID: String {
        meal.id.uuidString
    }
    
    var isEmpty: Bool {
        meal.foodItems.isEmpty
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
    
    func resetDrop() {
        droppedFoodItem = nil
        dropRecipient = nil
    }
    func tappedMoveForDrop() {
        guard let droppedFoodItem else { return }
        do {
            try DataManager.shared.moveMealItem(droppedFoodItem, to: meal, after: dropRecipient)
            resetDrop()
        } catch {
            print("Error moving dropped food item: \(error)")
        }
    }
    
    func tappedDuplicateForDrop() {
        guard let droppedFoodItem else { return }
        do {
            try DataManager.shared.duplicateMealItem(droppedFoodItem, to: meal, after: dropRecipient)
            resetDrop()
        } catch {
            print("Error moving dropped food item: \(error)")
        }
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
