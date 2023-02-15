import SwiftUI
import PrepDataTypes
import PrepCoreDataStack

public struct DayView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Binding var date: Date
    @StateObject var viewModel: ViewModel
    
    @State var dayMeals: [DayMeal] = []
    
    @State var nextTransitionIsForward = false
    @State var upcomingMealId: UUID? = nil
    @State var showingEmpty: Bool

    public init(date: Binding<Date>) {
        _date = date
        _viewModel = StateObject(wrappedValue: ViewModel(date: date.wrappedValue))
        
        let dayMeals = DataManager.shared.day(for: date.wrappedValue)?.meals ?? []
        _showingEmpty = State(initialValue: dayMeals.isEmpty)
    }
    
    public var body: some View {
        ZStack {
            backgroundLayer
            scrollViewLayer
            emptyViewLayer
        }
        .onChange(of: date, perform: dateChanged)
        .onChange(of: viewModel.dayMeals, perform: dayMealsChanged)
        .onChange(of: viewModel.showingEmpty, perform: showingEmptyChanged)
    }
    
    func showingEmptyChanged(to newValue: Bool) {
        withAnimation {
            showingEmpty = newValue
        }
    }
    
    func dayMealsChanged(to newValue: [DayMeal]) {
        withAnimation {
            print("Changing from \(self.dayMeals.count) items to \(newValue.count)")
            self.dayMeals = newValue
        }
    }
    
    func dateChanged(to newDate: Date) {
        self.nextTransitionIsForward = newDate > viewModel.date
        viewModel.date = date
    }
        
    var backgroundLayer: Color {
        colorScheme == .light ? Color(.systemGroupedBackground) : Color(hex: "191919")
    }
    
    var scrollViewLayer: some View {
        var transition: AnyTransition {
            .asymmetric(
                insertion: .move(edge: nextTransitionIsForward ? .trailing : .leading),
                removal: .move(edge: nextTransitionIsForward ? .leading : .trailing)
            )
        }
        
        return ScrollView(showsIndicators: false) {
            ForEach(dayMeals) { meal in
                mealView(for: meal)
                    .transition(transition)
            }
            Color.clear
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 55) }
        .scrollContentBackground(.hidden)
        .background(backgroundLayer)
    }
    
    var emptyViewLayer: some View {
        EmptyLayer(date: $date)
    }
    
    func mealView(for meal: DayMeal) -> some View {
        let isUpcomingMealBinding = Binding<Bool>(
            get: { meal.id == upcomingMealId },
            set: { _ in }
        )
        return MealsList.Meal(
            date: date,
            meal: meal,
            badgeWidths: .constant([:]),
            isUpcomingMeal: isUpcomingMealBinding,
            actionHandler: { _ in }
        )
    }
}

//NEXT:
/// [ ] Use previousDate below to mark the date before it's being transitioned—so that we can use it by the empty state to correctly show content (otherwise it changes to the "mark as fasted" content duringt he transition when moving back from yesterday to today.
/// [ ] Set showingEmpty initially
///
extension DayView {
    class ViewModel: ObservableObject {
        
        @Published var day: Day?
        @Published var dayMeals: [DayMeal]
        @Published var markedAsFasted: Bool = false
        
        @Published var emptyContentHeight: CGFloat = 0

        @Published var previousDate: Date = Date()
        @Published var showingEmpty: Bool = false

        var date: Date {
            didSet {
                dateChanged(date)
            }
        }
        
        init(date: Date) {
            self.date = date
            self.previousDate = date
            let day = DataManager.shared.day(for: date)
            self.day = day
            self.dayMeals = day?.meals ?? []
            self.showingEmpty = dayMeals.isEmpty
        }
    }
}

extension DayView.ViewModel {
    
    func dateChanged(_ newValue: Date) {
        let day = DataManager.shared.day(for: date)
        self.day = day
        self.dayMeals = day?.meals ?? []
        self.showingEmpty = dayMeals.isEmpty
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.previousDate = newValue
        }
    }
}
