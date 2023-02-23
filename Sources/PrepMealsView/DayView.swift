import SwiftUI
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics

public struct DayView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Binding var date: Date
    @Binding var dragTargetFoodItemId: UUID?
    @StateObject var viewModel: ViewModel

    @State var dayMeals: [DayMeal] = []
    
    @State var nextTransitionIsForward = false
    @State var upcomingMealId: UUID? = nil
    @State var showingEmpty: Bool
    
    @State var isAnimatingItemChange = false

    @State var id = UUID()

    @State var showingPreHeaderDropTarget = false
    @State var droppedPreHeaderItem: DropItem? = nil
    
    let actionHandler: (LogAction) -> ()

    public init(
        date: Binding<Date>,
        dragTargetFoodItemId: Binding<UUID?>,
        actionHandler: @escaping (LogAction) -> ()
    ) {
        _date = date
        _dragTargetFoodItemId = dragTargetFoodItemId
//        self.viewModel = viewModel
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.animatingMeal = false
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
            func handleDrop(_ items: [DropItem], location: CGPoint) -> Bool {
                droppedPreHeaderItem = items.first
                return true
            }
            
            func handleDropIsTargeted(_ isTargeted: Bool) {
                Haptics.selectionFeedback()
                withAnimation(.interactiveSpring()) {
                    showingPreHeaderDropTarget = isTargeted
                }
            }
            
            return MetricsView(
                date: $date,
                dayViewModel: viewModel,
                handleDropIsTargeted: handleDropIsTargeted,
                handleDrop: handleDrop
            )
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
        EmptyLayer(
            viewModel: viewModel,
            date: $date,
            actionHandler: actionHandler,
            initialShowingEmpty: showingEmpty
        )
//            .id(id)
//            .transition(.move(edge: .leading))
    }
    
    func mealView(for meal: Binding<DayMeal>) -> some View {
        let isUpcomingMealBinding = Binding<Bool>(
            get: { meal.wrappedValue.id == upcomingMealId },
            set: { _ in }
        )
        
        let showingPreHeaderDropTargetBinding = Binding<Bool>(
            get: {
                showingPreHeaderDropTarget
                && dayMeals.first?.id == meal.wrappedValue.id
            },
            set: { _ in }
        )
        
        let droppedPreHeaderItemBinding = Binding<DropItem?>(
            get: {
                guard dayMeals.first?.id == meal.wrappedValue.id else {
                    return nil
                }
                return droppedPreHeaderItem
            },
            set: { newValue in
                self.droppedPreHeaderItem = newValue
            }
        )
        return MealView(
            date: date,
            dayViewModel: viewModel,
            dragTargetFoodItemId: $dragTargetFoodItemId,
            showingPreHeaderDropTarget: showingPreHeaderDropTargetBinding,
            droppedPreHeaderItem: droppedPreHeaderItemBinding,
            mealBinding: meal,
            isUpcomingMeal: isUpcomingMealBinding,
            isAnimatingItemChange: $isAnimatingItemChange,
            actionHandler: actionHandler
        )
    }
}
