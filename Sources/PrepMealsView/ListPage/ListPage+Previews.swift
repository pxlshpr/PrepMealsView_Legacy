import SwiftUI
import PrepDataTypes

//MARK: - Filled

struct ListPagePreview: View {
    @Namespace var namespace
    
    var body: some View {
        NavigationView {
            listPage
                .navigationTitle("List Page")
        }
    }
    
    var listPage: some View {
        ListPage(
            date: Date(),
            meals: .constant(meals.map { DayMeal(from: $0) })
        ) { _ in
            /// Tapped Add meal
        }
    }
    
    var meals: [Meal] {
        [
            mockMeal("Breakfast", at: Date().h(8, r: true)),
            mockMeal("Lunch", at: Date().h(12, r: true)),
            mockMeal("Pre-workout Meal", at: Date().h(14, r: true))
        ]
    }
    
    func mockMeal(_ name: String, at time: Date) -> Meal {
        Meal(id: UUID(), day: day,
             name: name,
             time: time.timeIntervalSince1970,
             markedAsEatenAt: 0,
             foodItems: [],
             syncStatus: .notSynced, updatedAt: 0)
    }
    
    var day: Day {
        Day(id: "day", calendarDayString: "", addEnergyExpendituresToGoal: false, energyExpenditures: [], meals: [], syncStatus: .notSynced, updatedAt: 0)
    }
}

struct ListPage_Previews: PreviewProvider {
    static var previews: some View {
        ListPagePreview()
    }
}

//MARK: - Empty

struct EmptyListViewPreview: View {
    
    @Namespace var namespace
    
    var body: some View {
        ListPage(
            date: Date(),
            meals: .constant([]),
            onTapAddMeal: { _ in }
        )
    }
}

struct EmptyViewPreview: PreviewProvider {
    
    static var previews: some View {
        EmptyListViewPreview()
    }
}
