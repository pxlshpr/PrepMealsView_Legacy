import SwiftUI
import PrepDataTypes
import PrepCoreDataStack

extension MealsList.Meal {
    class ViewModel: ObservableObject {
        
        @Published var meal: DayMeal
        @Published var meals: [DayMeal]

        @Published var dragTargetFoodItemId: UUID? = nil
        
        @Published var droppedFoodItem: MealFoodItem? = nil
        @Published var dropRecipient: MealFoodItem? = nil

        @Published var targetId: UUID? = nil

        @Published var macrosIndicatorWidth: CGFloat = MacrosIndicator.DefaultWidth
        
        @Published var dateIsChanging: Bool = false
        
        init(meal: DayMeal, meals: [DayMeal]) {
            self.meal = meal
            self.meals = meals
            
            NotificationCenter.default.addObserver(
                self, selector: #selector(didAddFoodItemToMeal),
                name: .didAddFoodItemToMeal, object: nil)

            NotificationCenter.default.addObserver(
                self, selector: #selector(didUpdateMealFoodItem),
                name: .didUpdateMealFoodItem, object: nil)

            NotificationCenter.default.addObserver(
                self, selector: #selector(didDeleteFoodItemFromMeal),
                name: .didDeleteFoodItemFromMeal, object: nil)

            NotificationCenter.default.addObserver(
                self, selector: #selector(didUpdateFoodItems),
                name: .didUpdateFoodItems, object: nil)

            NotificationCenter.default.addObserver(
                self, selector: #selector(didUpdateMeal),
                name: .didUpdateMeal, object: nil)

//            NotificationCenter.default.addObserver(
//                self, selector: #selector(diaryWillChangeDate),
//                name: .weekPagerWillChangeDate, object: nil)
//            NotificationCenter.default.addObserver(
//                self, selector: #selector(diaryWillChangeDate),
//                name: .didPickDateOnDayView, object: nil)
//            NotificationCenter.default.addObserver(
//                self, selector: #selector(diaryWillChangeDate),
//                name: .dayPagerWillChangeDate, object: nil)

            self.macrosIndicatorWidth = calculateMacrosIndicatorWidth
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
        
        /// Make sure we don't have it already so we don't double add it
        guard meal.foodItems.contains(where: { $0.id == foodItem.id }) else {
            return
        }
        
        let mealFoodItem = MealFoodItem(from: foodItem)
        
        withAnimation(Bounce) {
            /// Update our local array used to calculate macro indicator widths first
            self.meals.addFoodItem(foodItem)

        }

        withAnimation(.interactiveSpring()) {
            
            /// Make sure this is the `MealView.ViewModel` for the `Meal` that the `FoodItem` belongs to before proceeding
            guard foodItem.meal?.id == meal.id else {
                self.macrosIndicatorWidth = calculateMacrosIndicatorWidth
                return
            }
            
            self.meal.foodItems.append(mealFoodItem)

            //TODO: Try simply appending it and then re-sorting it for that item
            // It should take the sort position, insert it correctly, and then reset all the numbers
            /// Re-sort the `foodItems` in case we moved an item within a meal
            resetSortPositions(aroundFoodItemWithId: foodItem.id)
        }
        
        withAnimation(Bounce) {
//            print("🔥 Calculating after ADD \(meal.name)")
            self.macrosIndicatorWidth = calculateMacrosIndicatorWidth
        }
    }
    
    @objc func didUpdateMealFoodItem(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let updatedFoodItem = userInfo[Notification.Keys.foodItem] as? FoodItem
        else {
            return
        }
        
        withAnimation(Bounce) {
            /// Update our local array used to calculate macro indicator widths first
            self.meals.updateFoodItem(updatedFoodItem)
        }

        withAnimation(.interactiveSpring()) {
            
            /// Make sure this is the `MealView.ViewModel` for the `Meal` that the `FoodItem` belongs to before proceeding
            guard
                updatedFoodItem.meal?.id == meal.id,
                let existingIndex = meal.foodItems.firstIndex(where: { $0.id == updatedFoodItem.id })
            else {
                self.macrosIndicatorWidth = calculateMacrosIndicatorWidth
                return
            }
            
            /// Replace the existing `MealFoodItem` with the updated one
            self.meal.foodItems[existingIndex] = MealFoodItem(from: updatedFoodItem)
            
            /// Re-sort the `foodItems` in case we moved an item within a meal
            resetSortPositions(aroundFoodItemWithId: updatedFoodItem.id)
        }
        
        withAnimation(Bounce) {
//            print("🔥 Calculating after UPDATE \(meal.name)")
            self.macrosIndicatorWidth = calculateMacrosIndicatorWidth
        }
    }

    @objc func didDeleteFoodItemFromMeal(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let id = userInfo[Notification.Keys.uuid] as? UUID
        else {
            return
        }

        withAnimation(Bounce) {
            self.meals.deleteFoodItem(with: id)
        }

        guard meal.foodItems.contains(where: { $0.id == id }) else {
//            print("🔥 Calculating after DELETE \(meal.name)")
            self.macrosIndicatorWidth = calculateMacrosIndicatorWidth
            return
        }
        
        withAnimation(.interactiveSpring()) {
            /// Update our local array used to calculate macro indicator widths first

            self.meal.foodItems.removeAll(where: { $0.id == id })
            resetSortPositions(aroundFoodItemWithId: nil)
        }
        withAnimation(Bounce) {
//            print("🔥 Calculating after DELETE \(meal.name)")
            self.macrosIndicatorWidth = calculateMacrosIndicatorWidth
        }
    }
    
    @objc func didUpdateFoodItems(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let foodItems = userInfo[Notification.Keys.foodItems] as? [FoodItem]
        else {
            return
        }
        
        let initialMeal = meal
        withAnimation {
            for foodItem in foodItems {
                
                /// If food item previously belong to this meal, remove it
                if let index = meal.foodItems.firstIndex(where: { $0.id == foodItem.id }) {
                    meal.foodItems.remove(at: index)
                }
                
                /// We're only interesting in items that belong to this meal
                guard foodItem.meal?.id == meal.id else {
                    continue
                }
                
                if let deletedAt = foodItem.deletedAt, deletedAt > 0 {
                    guard let index = meal.foodItems.firstIndex(where: { $0.id == foodItem.id }) else {
                        continue
                    }
                    meal.foodItems.remove(at: index)
                }

                
                /// Either add or update it dending on if it exists or not
                let mealFoodItem = MealFoodItem(from: foodItem)
                if let index = meal.foodItems.firstIndex(where: { $0.id == foodItem.id }) {
                    meal.foodItems[index] = mealFoodItem
                } else {
                    meal.foodItems.append(mealFoodItem)
                }
            }
            
            /// Update our local meals array so that the meter calculations will be correct
//            if let index = meals.firstIndex(where: { $0.id == meal.id }) {
//                meals[index] = meal
//            }
            meal.foodItems.sort { $0.sortPosition < $1.sortPosition }
        }
        
        if initialMeal != meal {
            print("\(meal.name) Sending didUpdateMeal")
            NotificationCenter.default.post(
                name: .didUpdateMeal,
                object: nil,
                userInfo: [Notification.Keys.meal : meal]
            )
        }
    }
    
    @objc func didUpdateMeal(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let updatedMeal = userInfo[Notification.Keys.meal] as? DayMeal else {
            return
        }
        
        print("\(meal.name) received")
        if let index = meals.firstIndex(where: { $0.id == updatedMeal.id }) {
            print("\(meal.name) is changing meal at index: \(index)")
            meals[index] = updatedMeal
        } else {
            print("\(meal.name) does not have meal? within \(meals.count)")
        }
        
        withAnimation(.interactiveSpring()) {
            self.macrosIndicatorWidth = self.calculateMacrosIndicatorWidth
            print("\(meal.name) now has width: \(macrosIndicatorWidth)")
        }
    }
}


extension Notification.Name {
    static var didUpdateMeal: Notification.Name { return .init("didUpdateMeal") }
}

extension MealsList.Meal.ViewModel {
    
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
    
}

let Bounce: Animation = .interactiveSpring(response: 0.35, dampingFraction: 0.66, blendDuration: 0.35)

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
//            resetDrop()
        } catch {
            print("Error moving dropped food item: \(error)")
        }
    }
    
    func tappedDuplicateForDrop() {
        guard let droppedFoodItem else { return }
        do {
            try DataManager.shared.duplicateMealItem(droppedFoodItem, to: meal, after: dropRecipient)
//            resetDrop()
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

import PrepViews

extension MealsList.Meal.ViewModel {
    
    var energyValuesInKcalDecreasing: [Double] {
        meals
            .filter { !$0.foodItems.isEmpty }
            .map { $0.energyValueInKcal }
            .sorted { $0 > $1 }
    }
    var largestEnergyInKcal: Double {
        energyValuesInKcalDecreasing.first ?? 0
    }
    
    var smallestEnergyInKcal: Double {
        energyValuesInKcalDecreasing.last ?? 0
    }
    
    var calculateMacrosIndicatorWidth: CGFloat {
        calculateMacrosIndicatorWidth(for: meal.energyValueInKcal, largest: largestEnergyInKcal, smallest: smallestEnergyInKcal)
//
//        let min = MacrosIndicator.DefaultWidth
//        let max: CGFloat = 100
//        let largest = largestEnergyInKcal
//        let smallest = smallestEnergyInKcal
//
//        guard largest > 0, smallest > 0 else {
//            return MacrosIndicator.DefaultWidth
//        }
//
//        /// First try and scale values such that smallest value gets the DefaultWidth and everything else scales accordingly
//        /// But first see if this results in the largest value crossing the MaxWidth, and if so
//        guard (largest/smallest) * min <= max else {
//            /// scale values such that largest value gets the MaxWidth and everything else scales accordingly
//            let percent = meal.energyValueInKcal/largest
//            return percent * max
//        }
//
//        let percent = meal.energyValueInKcal/smallest
//        return percent * min
    }

    func calculateMacrosIndicatorWidth(for value: Double, largest: Double, smallest: Double, maxWidth: CGFloat = 150) -> CGFloat {
        let min = MacrosIndicator.DefaultWidth
        let max: CGFloat = maxWidth
        
        guard largest > 0, smallest > 0, value <= largest, value >= smallest else {
            return MacrosIndicator.DefaultWidth
        }
        
        /// First try and scale values such that smallest value gets the DefaultWidth and everything else scales accordingly
        /// But first see if this results in the largest value crossing the MaxWidth, and if so
        guard (largest/smallest) * min <= max else {
            /// scale values such that largest value gets the MaxWidth and everything else scales accordingly
            let percent = value/largest
            let width = percent * max
            return width
        }
        
        let percent = value/smallest
        let width = percent * min
        return width
    }

    func calculateMacrosIndicatorWidth(of foodItem: MealFoodItem) -> CGFloat {
        calculateMacrosIndicatorWidth(
            for: foodItem.scaledValueForEnergyInKcal,
            largest: meal.largestEnergyInKcal,
            smallest: meal.smallestEnergyInKcal,
            maxWidth: 100
        )
    }
    
}

extension DayMeal {
    var energyValuesInKcalDecreasing: [Double] {
        foodItems
            .map { $0.scaledValueForEnergyInKcal }
            .sorted { $0 > $1 }
    }
    var largestEnergyInKcal: Double {
        energyValuesInKcalDecreasing.first ?? 0
    }
    
    var smallestEnergyInKcal: Double {
        energyValuesInKcalDecreasing.last ?? 0
    }
}
