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

    let initialMarkedAsFasted: Bool
    @State var markedAsFasted: Bool
    /// We're using this as a workaround for an issue where changing the date from outside the diary pager (ie using the week pager or date picker)
    /// sometimes causes the incorrect `markedAsFasted` (still unsure why this happens)
    /// Instead of spending too much time on this—this, in tandem with the code in `dateDidChange` and the `initialMarkedAsFasted` constant
    /// ensures that the correctly supplied value is set to begin with. We're also setting this in the `set` call of the `markedAsFastedBinding` for
    /// when the app initially loads and we don't get a `dateDidChange` call.
    @State var dateDidChangeOrMarkedAsFastedWasSet: Bool = false

    public init(
        date: Date,
        markedAsFasted: Bool = false,
        meals: Binding<[DayMeal]>,
        actionHandler: @escaping (MealsDiaryAction) -> ()
    ) {
        self.initialMarkedAsFasted = markedAsFasted
        _markedAsFasted = State(initialValue: markedAsFasted)
        self.date = date
        self.actionHandler = actionHandler
        _meals = meals
    }
    
    var markedAsFastedBinding: Binding<Bool> {
        Binding<Bool>(
            get: {
                dateDidChangeOrMarkedAsFastedWasSet ? markedAsFasted : initialMarkedAsFasted
            },
            set: {
                self.markedAsFasted = $0
                self.dateDidChangeOrMarkedAsFastedWasSet = true
            }
        )
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
        .task {
            print("❄️ task: \(date.calendarDayString)")
        }
        .onReceive(dateDidChange, perform: dateDidChange)
        .onReceive(didAddFoodItemToMeal, perform: didAddFoodItemToMeal)
        .onReceive(didUpdateMealFoodItem, perform: didUpdateMealFoodItem)
        .onReceive(didDeleteFoodItemFromMeal, perform: didDeleteFoodItemFromMeal)
        .onReceive(didDeleteMeal, perform: didDeleteMeal)
        .onChange(of: markedAsFasted, perform: markedAsFastedChanged)
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
        //TODO: Don't delay this for the initial load when app launches
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
              let date = userInfo[Notification.Keys.date] as? Date
        else { return }
        print("🌻 \(self.date.calendarDayString): MealList.dateDidChange(\(date.calendarDayString)), markedAsFasted: \(markedAsFasted)")
        print("🌻     - but it should be \(DataManager.shared.markedAsFasting(on: self.date))")
        self.markedAsFasted = DataManager.shared.markedAsFasting(on: self.date)
        self.dateDidChangeOrMarkedAsFastedWasSet = true
        if  date.startOfDay == self.date.startOfDay {
            calculateBadgeWidths()
        }
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
