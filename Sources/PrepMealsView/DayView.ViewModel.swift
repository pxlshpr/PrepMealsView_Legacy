import SwiftUI
import PrepDataTypes
import PrepCoreDataStack

extension DayView {
    class ViewModel: ObservableObject {
        
        @Published var day: Day?
        @Published var dayMeals: [DayMeal]
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
        
        init(date: Date) {
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
        animatingMeal = true
        self.reload()
    }
    
    @objc func initialSyncCompleted(notification: Notification) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            cprint("📩 initialSyncCompleted → DayView")
            self.animatingMeal = true
            self.reload()
//        }
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
        cprint("📩 didAddFoodItemToMeal → DayView")
        animatingMeal = true
        reload()
    }

    @objc func didDeleteFoodItemFromMeal(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let id = userInfo[Notification.Keys.uuid] as? UUID
        else { return }
        cprint("📩 didDeleteFoodItemFromMeal → DayView")
        resetSortPositions(afterDeletingId: id)
        animatingMeal = true
        reload()
    }
    
    @objc func didUpdateMealFoodItem(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let updatedFoodItem = userInfo[Notification.Keys.foodItem] as? FoodItem
        else { return }
        cprint("📩 didDeleteFoodItemFromMeal → DayView")
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
            
            print("-- Before setting updated item:")
            for foodItem in mealCopy.foodItems {
                print("    \(foodItem.sortPosition) \(foodItem.food.emoji) \(foodItem.food.name)")
            }
            
            if let updatedFoodItem {
                mealCopy.foodItems[existingIndex] = MealFoodItem(from: updatedFoodItem)
            } else if let deletedFoodItemId {
                mealCopy.foodItems.removeAll(where: { $0.id == deletedFoodItemId })
            }
            
            print("-- Before sorting:")
            for foodItem in mealCopy.foodItems {
                print("    \(foodItem.sortPosition) \(foodItem.food.emoji) \(foodItem.food.name)")
            }

            mealCopy.foodItems.resetSortPositions(aroundFoodItemWithId: updatedFoodItem?.id)
            mealCopy.foodItems.sort { $0.sortPosition < $1.sortPosition }

            print("-- After sorting:")
            for foodItem in mealCopy.foodItems {
                print("    \(foodItem.sortPosition) \(foodItem.food.emoji) \(foodItem.food.name)")
            }

            for oldItem in before {
                guard let newItem = mealCopy.foodItems.first(where: { $0.id == oldItem.id }) else {
                    continue
                }
                if newItem.sortPosition != oldItem.sortPosition {
                    do {
                        print("-- Silently updating: \(newItem.sortPosition) \(newItem.food.emoji) \(newItem.food.name)")
                        try DataManager.shared.silentlyUpdateSortPosition(for: newItem)
                    } catch {
                        cprint("Error updating sort position: \(error)")
                    }
                }
            }
            print(" ")
        }
    }
    
    @objc func didUpdateFoodItems(notification: Notification) {
        cprint("📩 didUpdateFoodItems → DayView")
        animatingMeal = true
        reload()
    }
    
    @objc func didUpdateMeal() {
        cprint("📩 didUpdateMeal → DayView")
        animatingMeal = true
        reload()
    }

    @objc func didAddMeal() {
        cprint("📩 didAddMeal → DayView, calling reload()")
        animatingMeal = true
        reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            cprint("📩     (2s later) calling reload() again")
            self.reload()
        }
    }

    @objc func didDeleteMeal() {
        cprint("📩 didDeleteMeal → DayView")
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
    }

    func dateChanged(_ newValue: Date) {
        load(for: newValue)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.previousDate = newValue
        }
    }
}
