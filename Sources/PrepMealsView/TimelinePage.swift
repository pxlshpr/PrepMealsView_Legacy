import SwiftUI
import Timeline
import PrepDataTypes

public struct TimelinePage: View {

    let didAddMeal = NotificationCenter.default.publisher(for: .didAddMeal)
    let didUpdateMeals = NotificationCenter.default.publisher(for: .didUpdateMeals)

    let date: Date
    let namespace: Namespace.ID
    let getMealsHandler: GetMealsHandler
    
    @State var timelineItems: [TimelineItem] = []

    public init(
        date: Date = Date(),
        getMealsHandler: @escaping GetMealsHandler,
        namespace: Namespace.ID
    ) {
        self.date = date
        self.namespace = namespace
        self.getMealsHandler = getMealsHandler
    }

    public var body: some View {
        timeline
            .onAppear(perform: appeared)
            .onReceive(didAddMeal, perform: didAddMeal)
            .onReceive(didUpdateMeals, perform: didUpdateMeals)
    }

    var timeline: some View {
        Timeline(items: timelineItems, matchedGeometryNamespace: namespace)
            .background(Color(.systemGroupedBackground))
    }

    //MARK: - Actions
    func didAddMeal(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let meal = userInfo[Notification.Keys.meal] as? Meal,
              meal.day.calendarDayString == self.date.calendarDayString
        else {
            return
        }
        getMeals()
    }
    
    func didUpdateMeals(notification: Notification) {
        getMeals()
    }
    
    func appeared() {
        getMeals(animated: false)
    }
    
    func getMeals(animated: Bool = true) {
        Task {
            do {
                let meals = try await getMealsHandler(date)
                await MainActor.run {
                    let sortedMeals = meals.sorted(by: { $0.time < $1.time })
                    let timelineItems = sortedMeals.map { TimelineItem(meal: $0) }
                    if animated {
                        withAnimation {
                            self.timelineItems = timelineItems
                        }
                    } else {
                        self.timelineItems = timelineItems
                    }
                }
            } catch {
                print("Error getting meals for: \(date)")
            }
        }
    }
//    var timelineItems: [TimelineItem] {
//        Store.timelineItems(for: date)
//    }
}
