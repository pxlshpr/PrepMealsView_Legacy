//import SwiftUI
//import SwiftUISugar
//import SwiftHaptics
//import PrepDataTypes
//
//public struct ListPage: View {
//    
//    @State var meals: [Meal] = []
//    
//    var date: Date
//    let namespace: Namespace.ID
//    
//    let getMealsHandler: GetMealsHandler
//    let didAddMeal = NotificationCenter.default.publisher(for: .didAddMeal)
//    let didUpdateMeals = NotificationCenter.default.publisher(for: .didUpdateMeals)
//
//    let tapAddMealHandler: EmptyHandler
//
//    public init(date: Date = Date(),
//         getMealsHandler: @escaping GetMealsHandler,
//         tapAddMealHandler: @escaping EmptyHandler,
//         namespace: Namespace.ID
//    ) {
//        self.date = date
//        self.getMealsHandler = getMealsHandler
//        self.namespace = namespace
//        self.tapAddMealHandler = tapAddMealHandler
//    }
//    
//    public var body: some View {
//        list
//            .onAppear(perform: appeared)
//            .onReceive(didAddMeal, perform: didAddMeal)
//            .onReceive(didUpdateMeals, perform: didUpdateMeals)
//    }
//    
//    var list: some View {
//        List {
//            ForEach(meals) { meal in
//                MealView(
//                    meal: meal,
//                    namespace: namespace
//                )
//            }
//            if !meals.isEmpty {
//                Spacer().frame(height: 20)
//                    .listRowSeparator(.hidden)
//                    .listRowBackground(Color(.systemGroupedBackground))
//            }
//            addMealButton
//        }
//        .listStyle(.plain)
//        .scrollContentBackground(.hidden)
//        .background(Color(.systemGroupedBackground))
//    }
//    
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
//    
//    func appeared() {
//        getMeals(animated: false)
//    }
//    
//    func getMeals(animated: Bool = true) {
//        Task {
//            do {
//                let meals = try await getMealsHandler(date)
//                await MainActor.run {
//                    let sortedMeals = meals.sorted(by: { $0.time < $1.time })
//                    if animated {
//                        withAnimation {
//                            self.meals = sortedMeals
//                        }
//                    } else {
//                        self.meals = sortedMeals
//                    }
//                }
//            } catch {
//                print("Error getting meals for: \(date)")
//            }
//        }
//    }
//    
//    var addMealButton: some View {
//        Section {
//            Button {
//                tapAddMealHandler()
//            } label: {
//                Text("Add Meal")
//                Spacer()
//            }
//            .buttonStyle(.borderless)
//            .listRowSeparator(.hidden)
//            .listRowBackground(
//                ListRowBackground(
//                    color: Color(.secondarySystemGroupedBackground),
//                    includeTopSeparator: true,
//                    includeBottomSeparator: true
//                )
//            )
//        }
//    }
//}
