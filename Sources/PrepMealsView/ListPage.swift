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
    
    @State var hoursAfterLastMeal = 2
    
    var addMealButton: some View {
        Section {
            HStack(spacing: 15) {
                Button {
                    
                } label: {
                    HStack {
                        Image(systemName: "note.text.badge.plus")
                        Text("Now")
                    }
                    .padding()
                    .background(
                        Capsule(style: .continuous)
//                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .foregroundColor(Color(.tertiarySystemFill))
                    )
                }
                .buttonStyle(.borderless)
//                Spacer()
                HStack(spacing: 15) {
                    Button {
                        
                    } label: {
                        HStack {
                            Image(systemName: "note.text.badge.plus")
                            Text("7 PM")
                        }
                        .padding()
                        .background(
                            Capsule(style: .continuous)
    //                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .foregroundColor(Color(.tertiarySystemFill))
                        )
                    }
                    .buttonStyle(.borderless)
                    Button {
                        let hours = max(hoursAfterLastMeal - 1, 1)
                        hoursAfterLastMeal = hours
                        //TODO: don't let hoursAfterLastMeal go past wee hours—we'll need the last meal data for this
                    } label: {
                        Image(systemName: "gobackward.60")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderless)
                    .disabled(hoursAfterLastMeal == 1)
                    Button {
                        hoursAfterLastMeal += 1
                    } label: {
                        Image(systemName: "goforward.60")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 20)
        .listRowBackground(
            ListRowBackground(
                color: Color(.systemGroupedBackground),
                includeTopSeparator: true,
                includeBottomSeparator: false
            )
        )
        .listRowSeparator(.hidden)
    }
    
    var addMealButton_legacy: some View {
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
                    Text("\(hoursAfterLastMeal)h after Christmas Dinner")
                        .lineLimit(1)
                }
                .buttonStyle(.borderless)
                Spacer()
                Button {
                    let hours = max(hoursAfterLastMeal - 1, 1)
                    hoursAfterLastMeal = hours
                    //TODO: don't let hoursAfterLastMeal go past wee hours—we'll need the last meal data for this
                } label: {
                    Image(systemName: "gobackward.60")
                }
                .buttonStyle(.borderless)
                .disabled(hoursAfterLastMeal == 1)
                Button {
                    hoursAfterLastMeal += 1
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
