import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes

public struct ListPage: View {
    
    let didAddMeal = NotificationCenter.default.publisher(for: .didAddMeal)
    let didUpdateMeals = NotificationCenter.default.publisher(for: .didUpdateMeals)
    let tapAddMealHandler: EmptyHandler

    @Binding var meals: [DayMeal]

    @Binding var shouldRefresh: Bool

    var namespace: Binding<Namespace.ID?>
    /// This is to mitigate an issue where `SwiftUIPager` would mess up the geometries of the adjacent pages
    /// by causing the items to have their original positions (with a horizontal offset placing them out of the screen) after a page,
    /// resulting in the matched geometry animation to animate them from the far edge of the screen.
    ///
    /// This immediately gets fixed after the first transition animation occurs, indicating that a redraw of the views refreshes their positions as well.
    /// The solution was to therefore detect once a page finished transitioning, and toggle a `Bool` that was attached to the `.id()`
    /// property of all the individual items within the page, forcing them to redraw.
    ///
    /// The issue however, was that this would cause the repeated assignments of the matched geometry identifiers to result in a warning that
    /// multiple views were using the same identifier. So to mitigate that, this `id` is added to the identifiers, giving them unique identifiers
    /// (while still matching them to their counterpart views) with each redraw.
    ///
    /// Furthermore, it must be noted that in order for the matched geometries to truly be reset—we must first use a conditional modifier on the
    /// view to change the namespace to a local one (not the one included in this struct)—effectively removing it from the global database.
    /// That is why the `namespace` is an optional—as we set it to nil as soon as the page transition occurs,
    /// and conditionally set the namespace to a local one as soon as that happens. We then reset it back to the namespace shared
    /// with the `TimelineView` (or any other views) after a tiny delay and this stops the warnings of the multiple views using the same id.
    @Binding var namespacePrefix: UUID

    public init(
         meals: Binding<[DayMeal]>,
         tapAddMealHandler: @escaping EmptyHandler,
         namespace: Binding<Namespace.ID?>,
         namespacePrefix: Binding<UUID>,
         shouldRefresh: Binding<Bool>
    ) {
        _meals = meals
        _shouldRefresh = shouldRefresh
        _namespacePrefix = namespacePrefix
        self.namespace = namespace
        self.tapAddMealHandler = tapAddMealHandler
    }
    
    public var body: some View {
        list
//            .onAppear(perform: appeared)
//            .onReceive(didAddMeal, perform: didAddMeal)
//            .onReceive(didUpdateMeals, perform: didUpdateMeals)
    }
    
    var list: some View {
        List {
            ForEach(meals) { meal in
                MealView(
                    meal: meal,
                    namespace: namespace,
                    namespacePrefix: $namespacePrefix,
                    shouldRefresh: $shouldRefresh
                )
            }
            if !meals.isEmpty {
                Spacer().frame(height: 20)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color(.systemGroupedBackground))
            }
            addMealButton
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }
    
//    func didAddMeal(notification: Notification) {
//        guard let userInfo = notification.userInfo,
//              let meal = userInfo[Notification.Keys.meal] as? Meal,
//              meal.day.calendarDayString == self.date.calendarDayString
//        else {
//            return
//        }
//        getMeals()
//    }
    
//    func didUpdateMeals(notification: Notification) {
//        getMeals()
//    }
//
//    func appeared() {
//        getMeals(animated: false)
//    }
    
    var addMealButton: some View {
        Section {
            Button {
                tapAddMealHandler()
            } label: {
                Text("Add Meal")
                Spacer()
            }
            .buttonStyle(.borderless)
            .listRowSeparator(.hidden)
            .listRowBackground(
                ListRowBackground(
                    color: Color(.secondarySystemGroupedBackground),
                    includeTopSeparator: true,
                    includeBottomSeparator: true
                )
            )
        }
    }
}
