import SwiftUI
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics

extension DayView {
    public class ViewModel: ObservableObject {
        
        @Published public var day: Day?
        @Published public var dayMeals: [DayMeal]
        @Published var markedAsFasted: Bool = false
        
        @Published var emptyContentHeight: CGFloat = 0

        @Published var previousDate: Date = Date()
        @Published var showingEmpty: Bool = false

        @Published var animatingMeal = false
        
        var date: Date {
            didSet {
                dateChanged(date)
            }
        }
        
        public init(date: Date) {
            self.date = date
            self.previousDate = date
            let day = DataManager.shared.day(for: date)
            self.day = day
            self.dayMeals = day?.meals ?? []
            self.showingEmpty = dayMeals.isEmpty
            
            addObservers()
        }
        
        public func reset(for date: Date) {
            self.date = date
            self.previousDate = date
            let day = DataManager.shared.day(for: date)
            self.day = day
            self.dayMeals = day?.meals ?? []
            self.showingEmpty = dayMeals.isEmpty
            
            addObservers()
        }
    }
}

extension DayView.ViewModel {
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didAddFoodItemToMeal), name: .didAddFoodItemToMeal, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDeleteFoodItemFromMeal), name: .didDeleteFoodItemFromMeal, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDeleteMeal), name: .didDeleteMeal, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateMealFoodItem), name: .didUpdateMealFoodItem, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateFoodItems), name: .didUpdateFoodItems, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(didAddMeal), name: .didAddMeal, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateMeal), name: .didUpdateMeal, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(didSetBadgeWidths), name: .didSetBadgeWidths, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(initialSyncCompleted), name: .initialSyncCompleted, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(shouldRefreshDay), name: .shouldRefreshDay, object: nil)

    }
    
    @objc func shouldRefreshDay(notification: Notification) {
        print("↔️ shouldRefreshDay → DayView — animatingMeal = true")
        animatingMeal = true
        self.reload()
    }
    
    @objc func initialSyncCompleted(notification: Notification) {
        print("↔️ initialSyncCompleted → DayView — animatingMeal = true")
        animatingMeal = true
        reload()
    }
    
    @objc func didSetBadgeWidths(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let date = userInfo[Notification.Keys.date] as? Date,
              date == self.date
        else { return }
        cprint("📩 didSetBadgeWidths → DayView")
        reload()
    }

    @objc func didAddFoodItemToMeal(notification: Notification) {
        print("↔️ didAddFoodItemToMeal → DayView — animatingMeal = true")
        animatingMeal = true
        reload()
    }

    @objc func didDeleteFoodItemFromMeal(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let id = userInfo[Notification.Keys.uuid] as? UUID
        else { return }
        print("↔️ didDeleteFoodItemFromMeal → DayView — animatingMeal = true")
        resetSortPositions(afterDeletingId: id)
        animatingMeal = true
        reload()
    }
    
    @objc func didUpdateMealFoodItem(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let updatedFoodItem = userInfo[Notification.Keys.foodItem] as? FoodItem
        else { return }
        print("↔️ didDeleteFoodItemFromMeal → DayView — animatingMeal = true")
        resetSortPositions(afterUpdating: updatedFoodItem)
        animatingMeal = true
        reload()
    }

    func resetSortPositions(afterUpdating updatedFoodItem: FoodItem) {
        resetSortPositions(updatedFoodItem: updatedFoodItem)
    }

    func resetSortPositions(afterDeletingId deletedFoodItemId: UUID) {
        resetSortPositions(deletedFoodItemId: deletedFoodItemId)
    }
    
    private func resetSortPositions(updatedFoodItem: FoodItem? = nil, deletedFoodItemId: UUID? = nil) {
        let id = updatedFoodItem?.id ?? deletedFoodItemId
        for meal in dayMeals {
            var mealCopy = meal
            guard let existingIndex = mealCopy.foodItems.firstIndex(where: { $0.id == id })
            else { continue }

            let before = mealCopy.foodItems
            
            cprint("🔀-- Before (2) setting updated item:")
            for foodItem in mealCopy.foodItems {
                cprint("🔀    \(foodItem.sortPosition) \(foodItem.food.emoji) \(foodItem.food.name)")
            }
            
            var movingForwards: Bool = false
            if let updatedFoodItem {
                let oldPosition = mealCopy.foodItems[existingIndex].sortPosition
                let newPosition = updatedFoodItem.sortPosition
                movingForwards = newPosition > oldPosition
                mealCopy.foodItems[existingIndex] = MealFoodItem(from: updatedFoodItem)
            } else if let deletedFoodItemId {
                mealCopy.foodItems.removeAll(where: { $0.id == deletedFoodItemId })
            }
            
            cprint("🔀-- Before sorting:")
            for foodItem in mealCopy.foodItems {
                cprint("🔀    \(foodItem.sortPosition) \(foodItem.food.emoji) \(foodItem.food.name)")
            }

            mealCopy.foodItems.resetSortPositions(
                aroundFoodItemWithId: updatedFoodItem?.id,
                movingForwards: movingForwards
            )
            mealCopy.foodItems.sort { $0.sortPosition < $1.sortPosition }

            cprint("🔀-- After sorting:")
            for foodItem in mealCopy.foodItems {
                cprint("🔀    \(foodItem.sortPosition) \(foodItem.food.emoji) \(foodItem.food.name)")
            }

            for oldItem in before {
                guard let newItem = mealCopy.foodItems.first(where: { $0.id == oldItem.id }) else {
                    continue
                }
//                if newItem.sortPosition != oldItem.sortPosition {
                    do {
                        cprint("🔀-- Silently updating: \(newItem.sortPosition) \(newItem.food.emoji) \(newItem.food.name)")
                        try DataManager.shared.silentlyUpdateSortPosition(for: newItem)
                    } catch {
                        cprint("🔀 Error updating sort position: \(error)")
                    }
//                }
            }
            cprint(" ")
        }
    }
    
    @objc func didUpdateFoodItems(notification: Notification) {
        print("↔️ didUpdateFoodItems → DayView — animatingMeal = true")
        animatingMeal = true
        reload()
    }
    
    @objc func didUpdateMeal() {
        print("↔️ didUpdateMeal → DayView — animatingMeal = true")
        animatingMeal = true
        reload()
    }

    @objc func didAddMeal() {
        print("↔️ didAddMeal → DayView — animatingMeal = true, calling reload() in 2s")
        animatingMeal = true
        reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            cprint("📩     (2s later) calling reload() again")
            self.reload()
        }
    }

    @objc func didDeleteMeal() {
        print("↔️ didDeleteMeal → DayView — animatingMeal = true")
        animatingMeal = true
        reload()
    }

    func reload() {
        load(for: date)
    }
    
    func load(for date: Date) {
        let day = DataManager.shared.day(for: date)
        self.day = day
        self.dayMeals = day?.meals ?? []
        cprint("🧨 ----------")
        cprint("🧨 DayView.load(for: \(date.calendarDayString)) — \(dayMeals.count) meals")
        for meal in dayMeals {
            cprint("🧨    Meal: \(meal.name) @ \(meal.timeString)")
            for foodItem in meal.foodItems {
                cprint("🧨        \(foodItem.sortPosition) \(foodItem.food.emoji) \(foodItem.food.name) - \(foodItem.badgeWidth)")
            }
        }
        self.showingEmpty = dayMeals.isEmpty
        cprint("🧨 ")
        
        print("↔️ DayView.load() — animatingMeal = false")
        animatingMeal = false

    }

    func dateChanged(_ newValue: Date) {
        load(for: newValue)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.previousDate = newValue
        }
    }
    
    func shouldAllowFooterDrop(for meal: DayMeal) -> Bool {
        availableMealTime(after: meal) != nil
    }
    
    func availableMealTime(after meal: DayMeal) -> Date? {
        return nil
    }
}

extension Array where Element == MealFoodItem {
    func copy(withNewMealId newMealId: UUID) -> [MealFoodItem] {
        self.map { $0.copy(withNewMealId: newMealId) }
    }
}

extension MealFoodItem {
    func copy(withNewMealId newMealId: UUID) -> MealFoodItem {
        MealFoodItem(
            id: UUID(),
            food: food,
            amount: amount,
            markedAsEatenAt: markedAsEatenAt,
            sortPosition: sortPosition,
            isSoftDeleted: isSoftDeleted,
            badgeWidth: badgeWidth,
            mealId: newMealId
        )
    }
}
extension DayMeal {
    var copy: DayMeal {
        let newMealId = UUID()
        let foodItemsCopy = foodItems.copy(withNewMealId: newMealId)
        return DayMeal(
            id: newMealId,
            name: name,
            time: time,
            markedAsEatenAt: markedAsEatenAt,
            goalSet: goalSet,
            foodItems: foodItemsCopy,
            badgeWidth: badgeWidth
        )
    }
}
extension DayView.ViewModel {
    
    func copyMeal(_ dayMeal: DayMeal, after targetMeal: DayMeal? = nil) {
        print("☎️ Copying meal: \(dayMeal.description)")
        let dayMealCopy = dayMeal.copy
        withAnimation {
            self.dayMeals = [dayMealCopy]
        }
        DataManager.shared.insertMealCopy(dayMealCopy, to: self.date, originalMealId: dayMeal.id)
    }

    func moveMeal(_ dayMeal: DayMeal, after targetMeal: DayMeal? = nil) {
        print("☎️ Moving meal: \(dayMeal.description)")
        withAnimation {
            self.dayMeals = [dayMeal]
        }
        DataManager.shared.moveMeal(dayMeal, to: self.date)
    }

    func moveItem(_ foodItem: MealFoodItem, to targetMeal: DayMeal, after targetFoodItem: MealFoodItem?) {
     
        guard let sourceMealId = foodItem.mealId else {
            return
        }
        
        let sourcePosition = foodItem.sortPosition
        let targetPosition: Int
        if let targetFoodItem {
            if targetMeal.id == sourceMealId {
                targetPosition = targetFoodItem.sortPosition
            } else {
                targetPosition = targetFoodItem.sortPosition + 1
            }
        } else {
            targetPosition = 1
        }

        if sourceMealId == targetMeal.id {
            
            cprint("☎️ Moving within same meal from: \(sourcePosition) to: \(targetPosition)")
            
            NotificationCenter.default.post(name: .swapMealFoodItemPositions, object: nil, userInfo: [
                Notification.Keys.mealId: sourceMealId,
                Notification.Keys.sourceItemPosition: sourcePosition - 1,
                Notification.Keys.targetItemPosition: targetPosition - 1
            ])

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                DataManager.shared.swapMealItem(
                    at: sourcePosition - 1, /// `- 1` to convert from 1-based position to 0-based index
                    and: targetPosition - 1,
                    inMealWithId: sourceMealId
                )
            }

        } else {
            
            cprint("☎️ Moving to another meal from: \(sourcePosition) to: \(targetPosition)")

            NotificationCenter.default.post(name: .removeMealFoodItemForMove, object: nil, userInfo: [
                Notification.Keys.mealId: sourceMealId,
                Notification.Keys.sourceItemPosition: sourcePosition
            ])

            NotificationCenter.default.post(name: .insertMealFoodItemForMove, object: nil, userInfo: [
                Notification.Keys.mealId: targetMeal.id,
                Notification.Keys.foodItem: foodItem,
                Notification.Keys.targetItemPosition: targetPosition
            ])
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                DataManager.shared.moveMealItem(
                    at: sourcePosition - 1, inMealWithId: sourceMealId,
                    to: targetPosition - 1, inMealWithId: targetMeal.id
                )
            }
        }
    }
}
