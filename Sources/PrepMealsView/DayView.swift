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
    
    @State var isAnimatingItemChange = false
    
    let actionHandler: (LogAction) -> ()

    public init(date: Binding<Date>, actionHandler: @escaping (LogAction) -> ()) {
        _date = date
        _viewModel = StateObject(wrappedValue: ViewModel(date: date.wrappedValue))
        self.actionHandler = actionHandler
        
        let dayMeals = DataManager.shared.day(for: date.wrappedValue)?.meals ?? []
        _dayMeals = State(initialValue: dayMeals)
        _showingEmpty = State(initialValue: dayMeals.isEmpty)
    }
    
    public var body: some View {
        ZStack {
            backgroundLayer
            scrollViewLayer
            emptyViewLayer
        }
        .onChange(of: date, perform: dateChanged)
        .onChange(of: viewModel.dayMeals, perform: viewModelDayMealsChanged)
        .onChange(of: viewModel.showingEmpty, perform: viewModelShowingEmptyChanged)
    }
    
    func viewModelShowingEmptyChanged(to newValue: Bool) {
        withAnimation {
            showingEmpty = newValue
        }
    }
    
    func viewModelDayMealsChanged(to newValue: [DayMeal]) {
        withAnimation {
            self.dayMeals = newValue
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.animatingMeal = false
        }
    }
    
    @State var id = UUID()

    func dateChanged(to newDate: Date) {
        self.nextTransitionIsForward = newDate > viewModel.date
        viewModel.date = date
        withAnimation {
            id = UUID()
        }
    }
        
    var backgroundLayer: Color {
        colorScheme == .light ? Color(.systemGroupedBackground) : Color(hex: "191919")
    }
    
    var scrollViewLayer: some View {
        var transition: AnyTransition {
            var insertion: AnyTransition {
                if isAnimatingItemChange {
                    return .opacity
                } else {
                    return .move(edge: nextTransitionIsForward ? .trailing : .leading)
                }
            }
            var removal: AnyTransition {
                if isAnimatingItemChange {
                    return .opacity
                } else {
                    return .move(edge: nextTransitionIsForward ? .leading : .trailing)
                }
            }
            return .asymmetric(insertion: insertion, removal: removal)
        }
        
        var metricsView: some View {
            MetricsView(date: $date)
//            .padding(.horizontal, 20)
//            /// ** Important ** This explicit height on the encompassing `ZStack` is crucial to ensure that
//            /// the separator heights of the `MealView`'s don't get messed up (it's a wierd bug that's device dependent).
//            .frame(height: 150)
            .id(id)
            .transition(transition)
        }
        
        var scrollView: some View {
            ScrollView(showsIndicators: false) {
//                metricsView
                ForEach(Array(dayMeals.enumerated()), id: \.element.id) { (index, item) in
                    mealView(for: $dayMeals[index])
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
        
//        return scrollView
        return VStack(spacing: 0) {
            metricsView
            Divider()
            scrollView
        }
//        .background(Color.accentColor)
        .background(backgroundLayer)
    }
    
    var emptyViewLayer: some View {
        EmptyLayer(date: $date, actionHandler: actionHandler, initialShowingEmpty: showingEmpty)
    }
    
    func mealView(for meal: DayMeal) -> some View {
        let isUpcomingMealBinding = Binding<Bool>(
            get: { meal.id == upcomingMealId },
            set: { _ in }
        )
        let mealBinding = Binding<DayMeal>(
            get: { meal },
            set: { _ in }
        )
        return MealView(
            date: date,
            mealBinding: mealBinding,
            isUpcomingMeal: isUpcomingMealBinding,
            isAnimatingItemChange: $isAnimatingItemChange,
            actionHandler: actionHandler
        )
    }
    
    func mealView(for meal: Binding<DayMeal>) -> some View {
        let isUpcomingMealBinding = Binding<Bool>(
            get: { meal.wrappedValue.id == upcomingMealId },
            set: { _ in }
        )
        return MealView(
            date: date,
            mealBinding: meal,
            isUpcomingMeal: isUpcomingMealBinding,
            isAnimatingItemChange: $isAnimatingItemChange,
            actionHandler: actionHandler
        )
    }
}
