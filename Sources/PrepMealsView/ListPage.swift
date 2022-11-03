import SwiftUI
import SwiftUISugar
import SwiftHaptics
import PrepDataTypes

public struct ListPage: View {
    
    let didAddMeal = NotificationCenter.default.publisher(for: .didAddMeal)
    let didUpdateMeals = NotificationCenter.default.publisher(for: .didUpdateMeals)
    let tapAddMealHandler: EmptyHandler

    @Binding var meals: [DayMeal]

    public init(
         meals: Binding<[DayMeal]>,
         tapAddMealHandler: @escaping EmptyHandler
    ) {
        _meals = meals
        self.tapAddMealHandler = tapAddMealHandler
    }
    
    public var body: some View {
        if meals.isEmpty {
            emptyContent
        } else {
            list
        }
    }
    
    var emptyContent: some View {
        ZStack {
            Color(.systemGroupedBackground)
            VStack {
                Text("You haven't prepped any meals yet")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(.tertiaryLabel))
                Button {
                    tapAddMealHandler()
                } label: {
                    Text("Add a Meal")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            Capsule(style: .continuous)
                                .foregroundColor(.accentColor)
                        )
                }
            }
            .padding()
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .foregroundColor(Color(.quaternarySystemFill))
            )
            .padding(.horizontal, 50)
        }
    }
    
    var list: some View {
        List {
            ForEach(meals) { meal in
                MealView(
                    meal: meal
//                    namespace: namespace,
//                    namespacePrefix: $namespacePrefix,
//                    shouldRefresh: $shouldRefresh
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
            HStack {
                Text("Add Meal")
                    .foregroundColor(.secondary)
                Text("•")
                    .foregroundColor(Color(.quaternaryLabel))
                Button {
                    tapAddMealHandler()
                } label: {
                    Text("Now")
                }
                .buttonStyle(.borderless)
                Text("•")
                    .foregroundColor(Color(.quaternaryLabel))
                Button {
                    tapAddMealHandler()
                } label: {
                    Text("2 hours after Dinner")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button {
                    tapAddMealHandler()
                } label: {
                    Image(systemName: "gobackward.60")
                }
                .buttonStyle(.borderless)
                Button {
                    tapAddMealHandler()
                } label: {
                    Image(systemName: "goforward.60")
                }
                .buttonStyle(.borderless)
            }
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

struct EmptyListViewPreview: View {
    
    @Namespace var namespace
    
    var body: some View {
        ListPage(
            meals: .constant([]),
            tapAddMealHandler: {}
        )
    }
}

struct EmptyViewPreview: PreviewProvider {
    
    static var previews: some View {
        EmptyListViewPreview()
    }
}

struct ListPagerPreview: View {
    @Namespace var namespace
    
    var body: some View {
        NavigationView {
            listPage
                .navigationTitle("List Page")
        }
    }
    
    var listPage: some View {
        ListPage(meals: .constant(meals.map { DayMeal(from: $0) })) {
            /// Tapped Add meal
        }
    }
    
    var meals: [Meal] {
        [
            mockMeal("Breakfast", at: Date()),
            mockMeal("Lunch", at: Date()),
            mockMeal("Dinner", at: Date())
        ]
    }
    
    func mockMeal(_ name: String, at time: Date) -> Meal {
        Meal(id: UUID(), day: day,
             name: name,
             time: Date().timeIntervalSince1970,
             markedAsEatenAt: 0,
             foodItems: [],
             syncStatus: .notSynced, updatedAt: 0)
    }
    
    var day: Day {
        Day(id: "day", calendarDayString: "", addEnergyExpendituresToGoal: false, energyExpenditures: [], meals: [], syncStatus: .notSynced, updatedAt: 0)
    }
}

struct ListPager_Previews: PreviewProvider {
    static var previews: some View {
        ListPagerPreview()
    }
}

extension DayMeal {
    init(from meal: Meal) {
        self.init(
            id: meal.id,
            name: meal.name,
            time: meal.time,
            foodItems: meal.foodItems
        )
    }
}
