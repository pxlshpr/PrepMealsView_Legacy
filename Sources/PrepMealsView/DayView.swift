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

    @State var showingBottomDropTarget = false
    @State var droppedBottomItem: DropItem? = nil

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
            func handleDrop(_ items: [DropItem], location: CGPoint) -> Bool {
                droppedBottomItem = items.first
                return true
            }
            
            func handleDropIsTargeted(_ isTargeted: Bool) {
                Haptics.selectionFeedback()
                withAnimation(.interactiveSpring()) {
                    showingBottomDropTarget = isTargeted
                }
            }
            
            var largeDropTargetView: some View {
                Text("Drop Here")
                    .bold()
                    .foregroundColor(.secondary)
                    .padding(.vertical, 50)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .foregroundColor(
                                Color.accentColor.opacity(colorScheme == .dark ? 0.4 : 0.2)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(
                                Color(.tertiaryLabel),
                                style: StrokeStyle(lineWidth: 1, dash: [5])
                            )
                    )
                    .padding(.horizontal, 12)
                    .transition(.scale)
                    .fixedSize(horizontal: false, vertical: true)
            }

            func actualScrollView(_ proxy: GeometryProxy) -> some View {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(dayMeals.enumerated()), id: \.element.id) { (index, item) in
                            mealView(for: $dayMeals[index])
                                .transition(transition)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Color.clear
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                        Group {
                            if showingBottomDropTarget {
                                VStack {
                                    largeDropTargetView
                                        .padding(.top, 8)
                                    Spacer()
                                }
                            } else {
                                Color.clear
                            }
                        }
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .dropDestination(
                            for: DropItem.self,
                            action: handleDrop,
                            isTargeted: handleDropIsTargeted
                        )
                    }
                    /// Using this to ensure we always have the scroll fill up the entire height,
                    /// so that the bottom drop target covers the entire blank space
                    .frame(minHeight: proxy.size.height - 55 - 8)
                }
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 55) }
                .scrollContentBackground(.hidden)
                .background(backgroundLayer)
            }
            
            return GeometryReader { proxy in
                actualScrollView(proxy)
            }
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
                guard dayMeals.first?.id == meal.wrappedValue.id else { return nil }
                return droppedPreHeaderItem
            },
            set: { newValue in
                self.droppedPreHeaderItem = newValue
            }
        )
        
        let showingBottomDropTargetBinding = Binding<Bool>(
            get: {
                showingBottomDropTarget
                && dayMeals.last?.id == meal.wrappedValue.id
            },
            set: { _ in }
        )
        
        let droppedBottomItemBinding = Binding<DropItem?>(
            get: {
                guard dayMeals.last?.id == meal.wrappedValue.id else { return nil }
                return droppedBottomItem
            },
            set: { newValue in
                self.droppedBottomItem = newValue
            }
        )
        
        return MealView(
            date: date,
            dayViewModel: viewModel,
            dragTargetFoodItemId: $dragTargetFoodItemId,
            showingPreHeaderDropTarget: showingPreHeaderDropTargetBinding,
            droppedPreHeaderItem: droppedPreHeaderItemBinding,
            showingBottomDropTarget: showingBottomDropTargetBinding,
            droppedBottomItem: droppedBottomItemBinding,
            mealBinding: meal,
            isUpcomingMeal: isUpcomingMealBinding,
            isAnimatingItemChange: $isAnimatingItemChange,
            actionHandler: actionHandler
        )
    }
}
