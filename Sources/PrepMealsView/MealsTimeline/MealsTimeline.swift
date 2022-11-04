import SwiftUI
import Timeline
import PrepDataTypes

public struct MealsTimeline: View {

    @State var timelineItems: [TimelineItem]

    public init(meals: Binding<[DayMeal]>) {
        let timelineItems = meals.wrappedValue.map { TimelineItem(dayMeal: $0) }
        _timelineItems = State(initialValue: timelineItems)
    }

    public var body: some View {
        timeline
    }

    var timeline: some View {
        Timeline(
            items: timelineItems
        )
        .background(Color(.systemGroupedBackground))
    }
}
