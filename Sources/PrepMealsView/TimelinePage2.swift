import SwiftUI
import Timeline
import PrepDataTypes

public struct TimelinePage2: View {

    let namespace: Namespace.ID
    @State var timelineItems: [TimelineItem]

    public init(
        meals: Binding<[Meal]>,
        namespace: Namespace.ID
    ) {
        let timelineItems = meals.wrappedValue.map { TimelineItem(meal: $0) }
        _timelineItems = State(initialValue: timelineItems)
        self.namespace = namespace
    }

    public var body: some View {
        timeline
            .onAppear(perform: appeared)
    }

    var timeline: some View {
        Timeline(items: timelineItems, matchedGeometryNamespace: namespace)
            .background(Color(.systemGroupedBackground))
    }

    //MARK: - Actions
//    func didAddMeal(notification: Notification) {
//        guard let userInfo = notification.userInfo,
//              let meal = userInfo[Notification.Keys.meal] as? Meal,
//              meal.day.calendarDayString == self.date.calendarDayString
//        else {
//            return
//        }
//        getMeals()
//    }
//
//    func didUpdateMeals(notification: Notification) {
//        getMeals()
//    }
    
    func appeared() {
//        getMeals(animated: false)
    }
    
//    func getMeals(animated: Bool = true) {
//        Task {
//            do {
//                let meals = try await getMealsHandler(date)
//                await MainActor.run {
//                    let sortedMeals = meals.sorted(by: { $0.time < $1.time })
//                    let timelineItems = sortedMeals.map { TimelineItem(meal: $0) }
//                    if animated {
//                        withAnimation {
//                            self.timelineItems = timelineItems
//                        }
//                    } else {
//                        self.timelineItems = timelineItems
//                    }
//                }
//            } catch {
//                print("Error getting meals for: \(date)")
//            }
//        }
//    }
//    var timelineItems: [TimelineItem] {
//        Store.timelineItems(for: date)
//    }
}
