import SwiftUI
import PrepDataTypes
import PrepCoreDataStack

public struct DayView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Binding var date: Date
    @StateObject var viewModel: ViewModel
    
    @State var dayMeals: [DayMeal] = []
    
    @State var nextTransitionIsForward = false
    @State var upcomingMealId: UUID? = nil
    @State var showingEmpty: Bool
    
    @State var isAnimatingItemChange = false
    
    let actionHandler: (LogAction) -> ()

    public init(date: Binding<Date>, actionHandler: @escaping (LogAction) -> ()) {
        _date = date
        _viewModel = StateObject(wrappedValue: ViewModel(date: date.wrappedValue))
        self.actionHandler = actionHandler
        
        let dayMeals = DataManager.shared.day(for: date.wrappedValue)?.meals ?? []
        _dayMeals = State(initialValue: dayMeals)
        _showingEmpty = State(initialValue: dayMeals.isEmpty)
    }
    
    public var body: some View {
        ZStack {
            backgroundLayer
            scrollViewLayer
            emptyViewLayer
        }
        .onChange(of: date, perform: dateChanged)
        .onChange(of: viewModel.dayMeals, perform: viewModelDayMealsChanged)
        .onChange(of: viewModel.showingEmpty, perform: viewModelShowingEmptyChanged)
    }
    
    func viewModelShowingEmptyChanged(to newValue: Bool) {
        withAnimation {
            showingEmpty = newValue
        }
    }
    
    func viewModelDayMealsChanged(to newValue: [DayMeal]) {
        withAnimation {
            self.dayMeals = newValue
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.animatingMeal = false
        }
    }
    
    @State var id = UUID()

    func dateChanged(to newDate: Date) {
        self.nextTransitionIsForward = newDate > viewModel.date
        viewModel.date = date
        withAnimation {
            id = UUID()
        }
    }
        
    var backgroundLayer: Color {
        colorScheme == .light ? Color(.systemGroupedBackground) : Color(hex: "191919")
    }
    
    var scrollViewLayer: some View {
        var transition: AnyTransition {
            var insertion: AnyTransition {
                if isAnimatingItemChange {
                    return .opacity
                } else {
                    return .move(edge: nextTransitionIsForward ? .trailing : .leading)
                }
            }
            var removal: AnyTransition {
                if isAnimatingItemChange {
                    return .opacity
                } else {
                    return .move(edge: nextTransitionIsForward ? .leading : .trailing)
                }
            }
            return .asymmetric(insertion: insertion, removal: removal)
        }
        
        var summaryView: some View {
            ZStack {
                Color.clear
                    .frame(height: 150)
                Text("Summary pager goes here")
            }
            /// ** Important ** This explicit height on the encompassing `ZStack` is crucial to ensure that
            /// the separator heights of the `MealView`'s don't get messed up (it's a wierd bug that's device dependent).
            .frame(height: 150)
            .id(id)
            .transition(transition)
        }
        
        return ScrollView(showsIndicators: false) {
            summaryView
            ForEach(Array(dayMeals.enumerated()), id: \.element.id) { (index, item) in
                mealView(for: $dayMeals[index])
                    .transition(transition)
            }
            Color.clear
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 55) }
        .scrollContentBackground(.hidden)
        .background(backgroundLayer)
    }
    
    var emptyViewLayer: some View {
        EmptyLayer(date: $date, actionHandler: actionHandler, initialShowingEmpty: showingEmpty)
    }
    
    func mealView(for meal: DayMeal) -> some View {
        let isUpcomingMealBinding = Binding<Bool>(
            get: { meal.id == upcomingMealId },
            set: { _ in }
        )
        let mealBinding = Binding<DayMeal>(
            get: { meal },
            set: { _ in }
        )
        return MealView(
            date: date,
            meal: meal,
            mealBinding: mealBinding,
            badgeWidths: .constant([:]),
            isUpcomingMeal: isUpcomingMealBinding,
            isAnimatingItemChange: $isAnimatingItemChange,
            actionHandler: actionHandler
        )
    }
    
    func mealView(for meal: Binding<DayMeal>) -> some View {
        let isUpcomingMealBinding = Binding<Bool>(
            get: { meal.wrappedValue.id == upcomingMealId },
            set: { _ in }
        )
        return MealView(
            date: date,
            meal: meal.wrappedValue,
            mealBinding: meal,
            badgeWidths: .constant([:]),
            isUpcomingMeal: isUpcomingMealBinding,
            isAnimatingItemChange: $isAnimatingItemChange,
            actionHandler: actionHandler
        )
    }
}

//NEXT:
/// [ ] Use previousDate below to mark the date before it's being transitioned—so that we can use it by the empty state to correctly show content (otherwise it changes to the "mark as fasted" content duringt he transition when moving back from yesterday to today.
/// [ ] Set showingEmpty initially
///
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
        NotificationCenter.default.addObserver(self, selector: #selector(didAddMeal), name: .didAddMeal, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDeleteMeal), name: .didDeleteMeal, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didAddFoodItemToMeal), name: .didAddFoodItemToMeal, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDeleteFoodItemFromMeal), name: .didDeleteFoodItemFromMeal, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateMealFoodItem), name: .didUpdateMealFoodItem, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateFoodItems), name: .didUpdateFoodItems, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateMeal), name: .didUpdateMeal, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didSetBadgeWidths), name: .didSetBadgeWidths, object: nil)
    }
    
    @objc func didSetBadgeWidths(notification: Notification) {
        print("💯 Received didSetBadgeWidths, calling reload()")
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
        print("💯 ----------")
        print("💯 DayView.load(for: \(date.calendarDayString)) — \(dayMeals.count) meals")
        for meal in dayMeals {
            print("💯    Meal: \(meal.name) @ \(meal.timeString)")
            for foodItem in meal.foodItems {
                print("💯        \(foodItem.sortPosition) \(foodItem.food.emoji) \(foodItem.food.name) - \(foodItem.badgeWidth)")
            }
        }
        print("💯 ")
        self.showingEmpty = dayMeals.isEmpty
    }

    func dateChanged(_ newValue: Date) {
        load(for: newValue)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.previousDate = newValue
        }
    }
}
