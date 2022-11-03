import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes

public struct ListPage2: View {
    
    let didAddMeal = NotificationCenter.default.publisher(for: .didAddMeal)
    let didUpdateMeals = NotificationCenter.default.publisher(for: .didUpdateMeals)
    let tapAddMealHandler: EmptyHandler

    @Binding var meals: [DayMeal]

    var namespace: Binding<Namespace.ID?>
    @Binding var shouldRefresh: Bool
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
