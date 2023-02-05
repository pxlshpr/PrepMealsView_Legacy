import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftSugar
import PrepCoreDataStack

public struct MealsList: View {
    
    let actionHandler: (MealsDiaryAction) -> ()

    let date: Date
    @Binding var meals: [DayMeal]

    @Environment(\.colorScheme) var colorScheme

    @State var animation: Animation? = .none
    
    @State var badgeWidths: [UUID : CGFloat] = [:]
    
    @State var emptyContentHeight: CGFloat = 0

    let didAddFoodItemToMeal = NotificationCenter.default.publisher(for: .didAddFoodItemToMeal)
    let didUpdateMealFoodItem = NotificationCenter.default.publisher(for: .didUpdateMealFoodItem)
    let didDeleteFoodItemFromMeal = NotificationCenter.default.publisher(for: .didDeleteFoodItemFromMeal)
    let didDeleteMeal = NotificationCenter.default.publisher(for: .didDeleteMeal)
    
    let dateDidChange = NotificationCenter.default.publisher(for: .dateDidChange)

    @State var hasAppeared: Bool = false
    
    public init(
        date: Date,
        meals: Binding<[DayMeal]>,
        actionHandler: @escaping (MealsDiaryAction) -> ()
    ) {
        self.date = date
        self.actionHandler = actionHandler
        _meals = meals
    }
    
    public var body: some View {
        Group {
            if hasAppeared {
                content
                    .transition(.opacity)
            } else {
                Color(.systemGroupedBackground)
            }
        }
        .onAppear(perform: appeared)
        .onReceive(dateDidChange, perform: dateDidChange)
        .onReceive(didAddFoodItemToMeal, perform: didAddFoodItemToMeal)
        .onReceive(didUpdateMealFoodItem, perform: didUpdateMealFoodItem)
        .onReceive(didDeleteFoodItemFromMeal, perform: didDeleteFoodItemFromMeal)
        .onReceive(didDeleteMeal, perform: didDeleteMeal)
    }
    
    var content: some View {
        ZStack {
            background
            Group {
                if meals.isEmpty {
                    emptyContent
                        .transition(.move(edge: .bottom))
                } else {
                    scrollView
                        .transition(.move(edge: .top))
                }
            }
        }
    }
}

extension MealsList {
    func appeared() {
        //TODO: Don't do this for the initial load when app launches
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                self.hasAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                calculateBadgeWidths()
            }
        }
    }
    
    var foodItemsCount: Int {
        meals.reduce(0) { $0 + $1.foodItems.count }
    }
    
    func calculateBadgeWidths() {
        Task {
            DataManager.shared.badgeWidths(on: date) { badgeWidths in
//                withAnimation(Bounce) {
                withAnimation(.interactiveSpring()) {
                    self.badgeWidths = badgeWidths
                }
            }
        }
    }

    func dateDidChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let date = userInfo[Notification.Keys.date] as? Date,
              date.startOfDay == self.date.startOfDay
        else { return }
        
        calculateBadgeWidths()
    }
    
    func didInvalidateBadgeWidths(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let date = userInfo[Notification.Keys.date] as? Date,
              date.startOfDay == self.date.startOfDay
        else { return }
        
        calculateBadgeWidths()
    }
}

extension MealsList {
    func didAddFoodItemToMeal(notification: Notification) {
        guard notificationMealIdBelongsHere(notification) else { return }
        calculateBadgeWidths()
    }
    
    func didUpdateMealFoodItem(notification: Notification) {
        guard notificationMealIdBelongsHere(notification) else { return }
        calculateBadgeWidths()
    }

    func didDeleteFoodItemFromMeal(notification: Notification) {
        guard notificationMealIdBelongsHere(notification) else { return }
        calculateBadgeWidths()
    }
    
    func didDeleteMeal(notification: Notification) {
        guard notificationMealIdBelongsHere(notification) else { return }
        calculateBadgeWidths()
    }
    
    func notificationMealIdBelongsHere(_ notification: Notification) -> Bool {
        guard let userInfo = notification.userInfo as? [String: AnyObject]
        else { return false }
        
        //TODO: Make id's in notifications explicit so weµ don't have to infer what they are
        if let mealId = userInfo[Notification.Keys.mealId] as? UUID {
            return meals.contains(where: { $0.id == mealId })
        }
        if let mealId = userInfo[Notification.Keys.uuid] as? UUID {
            return meals.contains(where: { $0.id == mealId })
        }
        return false
    }
}
