import SwiftUI
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics

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
        animatingMeal = true
        reload()
    }
    
    @objc func didSetBadgeWidths(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let date = userInfo[Notification.Keys.date] as? Date,
              date == self.date
        else { return }
        reload()
    }

    @objc func didAddFoodItemToMeal(notification: Notification) {
        animatingMeal = true
        reload()
    }

    @objc func didDeleteFoodItemFromMeal(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let id = userInfo[Notification.Keys.uuid] as? UUID
        else { return }
        resetSortPositions(afterDeletingId: id)
        animatingMeal = true
        reload()
    }
    
    @objc func didUpdateMealFoodItem(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
              let updatedFoodItem = userInfo[Notification.Keys.foodItem] as? FoodItem
        else { return }
        resetSortPositions(afterUpdating: updatedFoodItem)
        animatingMeal = true
        reload()
    }

    //TODO: Remove this
    func resetSortPositions(afterUpdating updatedFoodItem: FoodItem) {
        resetSortPositions(updatedFoodItem: updatedFoodItem)
    }

    //TODO: Remove this
    func resetSortPositions(afterDeletingId deletedFoodItemId: UUID) {
        resetSortPositions(deletedFoodItemId: deletedFoodItemId)
    }
    
    //TODO: Remove this
    private func resetSortPositions(updatedFoodItem: FoodItem? = nil, deletedFoodItemId: UUID? = nil) {
        let id = updatedFoodItem?.id ?? deletedFoodItemId
        for meal in dayMeals {
            var mealCopy = meal
            guard let existingIndex = mealCopy.foodItems.firstIndex(where: { $0.id == id })
            else { continue }

            let before = mealCopy.foodItems
            
            var movingForwards: Bool = false
            if let updatedFoodItem {
                let oldPosition = mealCopy.foodItems[existingIndex].sortPosition
                let newPosition = updatedFoodItem.sortPosition
                movingForwards = newPosition > oldPosition
                mealCopy.foodItems[existingIndex] = MealFoodItem(from: updatedFoodItem)
            } else if let deletedFoodItemId {
                mealCopy.foodItems.removeAll(where: { $0.id == deletedFoodItemId })
            }
            
            mealCopy.foodItems.resetSortPositions(
                aroundFoodItemWithId: updatedFoodItem?.id,
                movingForwards: movingForwards
            )
            mealCopy.foodItems.sort { $0.sortPosition < $1.sortPosition }

            for oldItem in before {
                guard let newItem = mealCopy.foodItems.first(where: { $0.id == oldItem.id }) else {
                    continue
                }
                do {
                    try DataManager.shared.silentlyUpdateSortPosition(for: newItem)
                } catch {
                }
            }
        }
    }
    
    @objc func didUpdateFoodItems(notification: Notification) {
        animatingMeal = true
        reload()
    }
    
    @objc func didUpdateMeal() {
        animatingMeal = true
        reload()
    }

    @objc func didAddMeal() {
        animatingMeal = true
        reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.reload()
        }
    }

    @objc func didDeleteMeal() {
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
        self.showingEmpty = dayMeals.isEmpty
        animatingMeal = false
    }

    func dateChanged(_ newValue: Date) {
        load(for: newValue)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.previousDate = newValue
        }
    }
}

extension DayView.ViewModel {
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
            
            print("☎️ Moving within same meal from: \(sourcePosition) to: \(targetPosition)")
            
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
            
            print("☎️ Moving to another meal from: \(sourcePosition) to: \(targetPosition)")

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
