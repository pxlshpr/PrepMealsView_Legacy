import SwiftUI
import PrepDataTypes
import PrepCoreDataStack

extension MealView {
    
    class ViewModel: ObservableObject {
        
        let date: Date
        
        @Published var meal: DayMeal
        @Published var hasPassed: Bool
        
        @Published var dragTargetFoodItemId: UUID? = nil
        @Published var droppedFoodItem: MealFoodItem? = nil
        @Published var dropRecipient: MealFoodItem? = nil
        @Published var targetId: UUID? = nil
        
        @Published var footerIsTargeted: Bool = false
        @Published var droppedFooterItem: DropItem? = nil

//        @Published var mealMacrosIndicatorWidth: CGFloat = FoodBadge.DefaultWidth
        @Published var dateIsChanging: Bool = false
        @Published var isUpcomingMeal: Bool
        @Published var isAnimatingItemChange = false
        
        @Published var energyValueInKcal: Double
        
//        @Published var foodItems: [MealFoodItem]
        
        let actionHandler: (LogAction) -> ()
        
        var timer: Timer? = nil
        
        init(
            date: Date,
            meal: DayMeal,
            isUpcomingMeal: Bool,
            actionHandler: @escaping (LogAction) -> ()
        ) {
            cprint("MealView.ViewModel.init for \(meal.name) on \(date.calendarDayString)")

            self.date = date
            self.meal = meal
            self.energyValueInKcal = meal.energyValueInKcal
            
            self.isUpcomingMeal = isUpcomingMeal
            self.hasPassed = meal.timeDate < Date()
            self.actionHandler = actionHandler
            
//            self.foodItems = meal.foodItems
//            self.mealMacrosIndicatorWidth = meal.badgeWidth
            addNotifications()
            scheduleUpdateTime()
        }
        
        func scheduleUpdateTime() {
            timer?.invalidate()
            timer = Timer(
                fireAt: meal.timeDate,
                interval: 0,
                target: self,
                selector: #selector(updateHasPassed),
                userInfo: nil,
                repeats: false
            )
            guard timer != nil else { return }
            RunLoop.main.add(timer!, forMode: .common)
            cprint("⏲ Scheduled timer for \(meal.name) @ \(meal.timeDate.shortTime)")
        }
        
        @objc func updateHasPassed() {
            cprint("⏲ Timer fired for \(meal.name) ...")

            let hasPassed = meal.timeDate <= Date()
            if self.hasPassed != hasPassed {
                cprint("⏲ ... hasPassed it different (now \(hasPassed)) so setting with animation")
                withAnimation {
                    self.hasPassed = hasPassed
                }
                cprint("⏲ ... posting shouldUpdateUpcomingMeal notification")
                NotificationCenter.default.post(name: .shouldUpdateUpcomingMeal, object: nil)
            } else {
                cprint("⏲ ... hasPassed isn't different and is still \(self.hasPassed)")
            }
        }
        
        deinit {
            timer?.invalidate()
        }

        func addNotifications() {
//            NotificationCenter.default.addObserver(
//                self, selector: #selector(didAddFoodItemToMeal),
//                name: .didAddFoodItemToMeal, object: nil)

            NotificationCenter.default.addObserver(
                self, selector: #selector(didUpdateMealFoodItem),
                name: .didUpdateMealFoodItem, object: nil)

//            NotificationCenter.default.addObserver(
//                self, selector: #selector(didDeleteFoodItemFromMeal),
//                name: .didDeleteFoodItemFromMeal, object: nil)
//
//            NotificationCenter.default.addObserver(
//                self, selector: #selector(didUpdateFoodItems),
//                name: .didUpdateFoodItems, object: nil)
//
//            NotificationCenter.default.addObserver(
//                self, selector: #selector(didUpdateMeal),
//                name: .didUpdateMeal, object: nil)
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
        
        /// Make sure we don't have it already so we don't double add it
        guard !meal.foodItems.contains(where: { $0.id == foodItem.id }) else {
            return
        }
        
        /// Make sure this is the `MealView.ViewModel` for the `Meal` that the `FoodItem` belongs to before proceeding
        guard foodItem.meal?.id == meal.id else {
            return
        }
        
        let mealFoodItem = MealFoodItem(from: foodItem)
        self.isAnimatingItemChange = true
        withAnimation(.interactiveSpring()) {
            meal.foodItems.append(mealFoodItem)
            resetSortPositions(aroundFoodItemWithId: foodItem.id)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isAnimatingItemChange = false
        }
        
//        NotificationCenter.default.post(
//            name: .didInvalidateBadgeWidths,
//            object: nil,
//            userInfo: [Notification.Keys.date : date]
//        )
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
            
            cprint("🔀-- Before setting updated item:")
            for foodItem in self.meal.foodItems {
                cprint("🔀    \(foodItem.sortPosition) \(foodItem.food.emoji) \(foodItem.food.name)")
            }

            /// Replace the existing `MealFoodItem` with the updated one
            self.meal.foodItems[existingIndex] = MealFoodItem(from: updatedFoodItem)
            
            /// Re-sort the `foodItems` in case we moved an item within a meal
            resetSortPositions(aroundFoodItemWithId: updatedFoodItem.id)
            
            energyValueInKcal = self.meal.energyValueInKcal
        }
        
        NotificationCenter.default.post(
            name: .didInvalidateBadgeWidths,
            object: nil,
            userInfo: [Notification.Keys.date : date]
        )

//        SyncManager.shared.resume()
    }

    @objc func didDeleteFoodItemFromMeal(notification: Notification) {
        cprint("Sending notification")

        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let id = userInfo[Notification.Keys.uuid] as? UUID
        else {
            return
        }

        guard meal.foodItems.contains(where: { $0.id == id }) else {
            return
        }
        
        guard let index = meal.foodItems.firstIndex(where: { $0.id == id }) else {
            return
        }

        self.isAnimatingItemChange = true
        withAnimation(.interactiveSpring()) {
            cprint("Food before deletion:")
            for foodItem in meal.foodItems {
                cprint("    \(foodItem.food.emoji) - \(foodItem.food.name)")
            }
            let _ = meal.foodItems.remove(at: index)
//            foodItems.removeAll(where: { $0.id == id })
            cprint("Food AFTER deletion:")
            for foodItem in meal.foodItems {
                cprint("    \(foodItem.food.emoji) - \(foodItem.food.name)")
            }
            resetSortPositions(aroundFoodItemWithId: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isAnimatingItemChange = false
        }

//        NotificationCenter.default.post(
//            name: .didInvalidateBadgeWidths,
//            object: nil,
//            userInfo: [Notification.Keys.date : date]
//        )
    }
    
    @objc func didUpdateFoodItems(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let foodItems = userInfo[Notification.Keys.foodItems] as? [FoodItem]
        else {
            return
        }
        
        cprint("didUpdateFoodItems received with: \(foodItems.count) foodItems")
        
        let initialMeal = meal
        self.isAnimatingItemChange = true
        withAnimation {
            for foodItem in foodItems {
                
                /// If food item previously belong to this meal, remove it
                if let index = self.meal.foodItems.firstIndex(where: { $0.id == foodItem.id }) {
                    self.meal.foodItems.remove(at: index)
                }
                
                /// We're only interesting in items that belong to this meal
                guard foodItem.meal?.id == meal.id else {
                    continue
                }
                
                if let deletedAt = foodItem.deletedAt, deletedAt > 0 {
                    guard let index = self.meal.foodItems.firstIndex(where: { $0.id == foodItem.id }) else {
                        continue
                    }
                    self.meal.foodItems.remove(at: index)
                }

                
                /// Either add or update it dending on if it exists or not
                let mealFoodItem = MealFoodItem(from: foodItem)
                if let index = self.meal.foodItems.firstIndex(where: { $0.id == foodItem.id }) {
                    self.meal.foodItems[index] = mealFoodItem
                } else {
                    self.meal.foodItems.append(mealFoodItem)
                }
            }
            
            /// Update our local meals array so that the meter calculations will be correct
//            if let index = meals.firstIndex(where: { $0.id == meal.id }) {
//                meals[index] = meal
//            }
            self.meal.foodItems.sort { $0.sortPosition < $1.sortPosition }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isAnimatingItemChange = false
        }

        if initialMeal != meal {
//            cprint("\(meal.name) Sending didUpdateMeal")
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
//            cprint("\(meal.name) now has width: \(macrosIndicatorWidth)")
        }
        updateHasPassed()
        scheduleUpdateTime()
    }
}


extension MealView.ViewModel {
    
    func resetSortPositions(aroundFoodItemWithId id: UUID?) {
        let before = self.meal.foodItems
        
        print("🔃 -- Before sorting:")
        for foodItem in meal.foodItems {
            print("🔃    \(foodItem.sortPosition) \(foodItem.food.emoji) \(foodItem.food.name)")
        }
        
        self.meal.foodItems.resetSortPositions(aroundFoodItemWithId: id)
        self.meal.foodItems.sort { $0.sortPosition < $1.sortPosition }

        print("🔃 -- After sorting:")
        for foodItem in meal.foodItems {
            print("🔃    \(foodItem.sortPosition) \(foodItem.food.emoji) \(foodItem.food.name)")
        }

        for oldItem in before {
            guard let newItem = self.meal.foodItems.first(where: { $0.id == oldItem.id }) else {
                /// We shouldn't get here
                continue
            }
            if newItem.sortPosition != oldItem.sortPosition {
                do {
                    try DataManager.shared.silentlyUpdateSortPosition(for: newItem)
                } catch {
                    cprint("Error updating sort position: \(error)")
                }
            }
        }
    }
    
}

extension MealView.ViewModel {
    
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
        ||
        meal.foodItems.allSatisfy({ $0.isSoftDeleted })
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
        droppedFooterItem = nil
        dropRecipient = nil
    }
    
    func tappedMoveForDrop() {
        guard let droppedFoodItem else { return }
        do {
            try DataManager.shared.moveMealItem(droppedFoodItem, to: meal, after: dropRecipient)
        } catch {
            cprint("Error moving dropped food item: \(error)")
        }
    }
    
    func tappedDuplicateForDrop() {
        guard let droppedFoodItem else { return }
        do {
            try DataManager.shared.duplicateMealItem(droppedFoodItem, to: meal, after: dropRecipient)
//            resetDrop()
        } catch {
            cprint("Error moving dropped food item: \(error)")
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

extension MealView.ViewModel {
    var isTargetingLastCell: Bool {
        dragTargetFoodItemId == meal.foodItems.last?.id
    }
    
    var shouldShowFooterTopSeparatorBinding: Binding<Bool> {
        Binding<Bool>(
            get: {
                /// if we're currently targeting last cell, don't show it
                guard !self.isTargetingLastCell else { return false }
                
                /// Otherwise only show it if we're not empty
                return !self.meal.foodItems.isEmpty
            },
            set: { _ in }
        )
    }
    
    func shouldShowTopSeparator(for item: MealFoodItem) -> Bool {
        /// if the meal header is being targeted on and this is the first cell
//        if targetId == meal.id, item.id == meal.foodItems.first?.id {
//            return true
//        }
        
        return false
    }
    
    func shouldShowBottomSeparator(for item: MealFoodItem) -> Bool {
        /// If this cell is being targeted,  and its the last one, show it
//        if item.id == meal.foodItems.last?.id, dragTargetFoodItemId == item.id {
//            return true
//        }
        
        return false
    }

    func shouldShowDivider(for item: MealFoodItem) -> Bool {
        /// if this is the last cell, never show it
        if item.id == meal.foodItems.last?.id {
            return false
        }
        
        /// If this cell is being targeted, don't show it
        if dragTargetFoodItemId == item.id {
            return false
        }
        
        return true
    }
}

import PrepViews

extension MealView.ViewModel {
    
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
