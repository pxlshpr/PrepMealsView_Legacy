import SwiftUI
import PrepDataTypes
import PrepCoreDataStack

extension MealsList.Meal {
    class ViewModel: ObservableObject {
        
        
        let date: Date
        
        @Published var meal: DayMeal
//        @Published var meals: [DayMeal]

        @Published var dragTargetFoodItemId: UUID? = nil
        
        @Published var droppedFoodItem: MealFoodItem? = nil
        @Published var dropRecipient: MealFoodItem? = nil

        @Published var targetId: UUID? = nil

        @Published var mealMacrosIndicatorWidth: CGFloat = FoodBadge.DefaultWidth
        
        @Published var dateIsChanging: Bool = false
        
        @Published var isUpcomingMeal: Bool
        
        let actionHandler: (MealsDiaryAction) -> ()
//        let didTapEditMeal: (DayMeal) -> ()
//        let didTapAddFood: (DayMeal) -> ()
//        let didTapMealFoodItem: (MealFoodItem, DayMeal) -> ()
        
        init(
            date: Date,
            meal: DayMeal,
//            meals: [DayMeal],
            isUpcomingMeal: Bool,
            actionHandler: @escaping (MealsDiaryAction) -> ()
//            didTapAddFood: @escaping (DayMeal) -> (),
//            didTapEditMeal: @escaping (DayMeal) -> (),
//            didTapMealFoodItem: @escaping (MealFoodItem, DayMeal) -> ()
        ) {
            self.date = date
            self.meal = meal
            self.isUpcomingMeal = isUpcomingMeal
//            self.meals = meals
            self.actionHandler = actionHandler
//            self.didTapEditMeal = didTapEditMeal
//            self.didTapAddFood = didTapAddFood
//            self.didTapMealFoodItem = didTapMealFoodItem
            
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
            
//            print("🧮 Calculating width in init")
            self.mealMacrosIndicatorWidth = meal.macrosIndicatorWidth
//            self.macrosIndicatorWidth = calculateMacrosIndicatorWidth
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
        guard !meal.foodItems.contains(where: { $0.id == foodItem.id }) else {
            return
        }
        
        withAnimation(Bounce) {
            /// Update our local array used to calculate macro indicator widths first
//            self.meals.addFoodItem(foodItem)
        }

        /// Make sure this is the `MealView.ViewModel` for the `Meal` that the `FoodItem` belongs to before proceeding
        guard foodItem.meal?.id == meal.id else {
            return
        }
        
        let mealFoodItem = MealFoodItem(from: foodItem)
        withAnimation(.interactiveSpring()) {
            meal.foodItems.append(mealFoodItem)
            resetSortPositions(aroundFoodItemWithId: foodItem.id)
        }
        
        NotificationCenter.default.post(
            name: .didInvalidateBadgeWidths,
            object: nil,
            userInfo: [Notification.Keys.date : date]
        )
    }
    
    @objc func didUpdateMealFoodItem(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let updatedFoodItem = userInfo[Notification.Keys.foodItem] as? FoodItem
        else {
            return
        }
        
        withAnimation(Bounce) {
            /// Update our local array used to calculate macro indicator widths first
//            self.meals.updateFoodItem(updatedFoodItem)
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
        
        NotificationCenter.default.post(
            name: .didInvalidateBadgeWidths,
            object: nil,
            userInfo: [Notification.Keys.date : date]
        )

        SyncManager.shared.resume()
    }

    @objc func didDeleteFoodItemFromMeal(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let id = userInfo[Notification.Keys.uuid] as? UUID
        else {
            return
        }

        withAnimation(Bounce) {
//            self.meals.deleteFoodItem(with: id)
        }

        guard meal.foodItems.contains(where: { $0.id == id }) else {
            return
        }
        
        withAnimation(.interactiveSpring()) {
            meal.foodItems.removeAll(where: { $0.id == id })
            resetSortPositions(aroundFoodItemWithId: nil)
        }
        
        NotificationCenter.default.post(
            name: .didInvalidateBadgeWidths,
            object: nil,
            userInfo: [Notification.Keys.date : date]
        )
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
//            print("\(meal.name) Sending didUpdateMeal")
            NotificationCenter.default.post(
                name: .didUpdateMeal,
                object: nil,
                userInfo: [Notification.Keys.dayMeal : meal]
            )
        }
    }
    
    @objc func didUpdateMeal(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let updatedMeal = userInfo[Notification.Keys.dayMeal] as? DayMeal else {
            return
        }
        
//        if let index = meals.firstIndex(where: { $0.id == updatedMeal.id }) {
//            meals[index] = updatedMeal
//        } else {
//        }
        
        withAnimation(.interactiveSpring()) {
            if meal.id == updatedMeal.id {
                self.meal = updatedMeal
            }
//            self.mealMacrosIndicatorWidth = self.calculatedMealMacrosIndicatorWidth
//            print("\(meal.name) now has width: \(macrosIndicatorWidth)")
        }
    }
}


extension MealsList.Meal.ViewModel {
    
    func resetSortPositions(aroundFoodItemWithId id: UUID?) {
        let before = self.meal.foodItems
        
        self.meal.foodItems.resetSortPositions(aroundFoodItemWithId: id)
        self.meal.foodItems.sort { $0.sortPosition < $1.sortPosition }
        
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

//TODO: Move this elsewhere
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
            
            /// Now insert it where it actually belongs
            var newIndex = removed.sortPosition - 1
            
//            print("🔀 newIndex for: \(removed.food.name) is \(newIndex)")
            if newIndex > self.count {
                newIndex = self.count
//                print("🔀 Changed newIndex to \(newIndex) since it was out of bounds (greater than \(self.count))")
            }
            
            if newIndex <= self.count , newIndex >= 0 {
//                print("🔀 Inserting \(removed.food.name) at \(newIndex)")
                self.insert(removed, at: newIndex)
            } else {
//                print("🔀 NOT Inserting \(removed.food.name) at \(newIndex) because it's out of bounds")
            }
        }

//        print("🔀 Before re-number: \(map({ "\($0.sortPosition)" }).joined(separator: ", "))")

        /// Finally, renumber all the items for the array just to be safe (can be optimised later)
        for i in self.indices {
            self[i].sortPosition = i + 1
        }
        
//        print("🔀 After re-number: \(map({ "\($0.sortPosition)" }).joined(separator: ", "))")
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

extension DayMeal {
    var timeDate: Date {
        Date(timeIntervalSince1970: time)
    }
}

extension MealsList.Meal.ViewModel {
    
    var isInFuture: Bool {
        meal.timeDate >= Date()
    }
    
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
            SyncManager.shared.pause()
//            print("🔀 Before move: \(meal.foodItems.map({ "\($0.sortPosition)" }).joined(separator: ", "))")
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
    
//    var energyValuesInKcalDecreasing: [Double] {
//        meals
//            .filter { !$0.foodItems.isEmpty }
//            .map { $0.energyValueInKcal }
//            .sorted { $0 > $1 }
//    }
//    var largestEnergyInKcal: Double {
//        energyValuesInKcalDecreasing.first ?? 0
//    }
//
//    var smallestEnergyInKcal: Double {
//        energyValuesInKcalDecreasing.last ?? 0
//    }
//
//    var calculatedMealMacrosIndicatorWidth: CGFloat {
//        calculateMacrosIndicatorWidth(for: meal.energyValueInKcal, largest: largestEnergyInKcal, smallest: smallestEnergyInKcal)
//    }
//
//    func calculateMacrosIndicatorWidth(for value: Double, largest: Double, smallest: Double, maxWidth: CGFloat = 150) -> CGFloat {
//        let min = FoodBadge.DefaultWidth
//        let max: CGFloat = maxWidth
//
//        guard largest > 0, smallest > 0, value <= largest, value >= smallest else {
//            return FoodBadge.DefaultWidth
//        }
//
//        /// First try and scale values such that smallest value gets the DefaultWidth and everything else scales accordingly
//        /// But first see if this results in the largest value crossing the MaxWidth, and if so
//        guard (largest/smallest) * min <= max else {
//            /// scale values such that largest value gets the MaxWidth and everything else scales accordingly
//            let percent = value/largest
//            let width = percent * max
//            return width
//        }
//
//        let percent = value/smallest
//        let width = percent * min
//        return width
//    }
//
//    func calculateMacrosIndicatorWidth(of foodItem: MealFoodItem) -> CGFloat {
//        calculateMacrosIndicatorWidth(
//            for: foodItem.scaledValueForEnergyInKcal,
//            largest: meal.largestEnergyInKcal,
//            smallest: meal.smallestEnergyInKcal,
//            maxWidth: 100
//        )
//    }
    
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
