import SwiftUI
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics

//MARK: - DayView.EmptyLayer

extension DayView {
    struct EmptyLayer: View {
        
        @Environment(\.colorScheme) var colorScheme
        @ObservedObject var viewModel: DayView.ViewModel
        @Binding var date: Date
        let actionHandler: (LogAction) -> ()

        @State var previousDate: Date = Date()
        @State var previousShowingEmpty: Bool = false
        @State var currentShowingEmpty: Bool = true
        @State var animatingMeal: Bool = false
        
        @State var droppedItem: DropItem? = nil
        @State var isTargetedForDrop: Bool = false
        @State var showingDropOptions: Bool = false
        
        let shouldRefreshDay = NotificationCenter.default.publisher(for: .shouldRefreshDay)
        let didAddMeal = NotificationCenter.default.publisher(for: .didAddMeal)
        let didDeleteMeal = NotificationCenter.default.publisher(for: .didDeleteMeal)
        let initialSyncCompleted = NotificationCenter.default.publisher(for: .initialSyncCompleted)
        
        init(
            viewModel: DayView.ViewModel,
            date: Binding<Date>,
            actionHandler: @escaping (LogAction) -> (),
            initialShowingEmpty: Bool = false
        ) {
            self.viewModel = viewModel
            _date = date
            self.actionHandler = actionHandler
            _currentShowingEmpty = State(initialValue: initialShowingEmpty)
        }
    }
}

extension DayView.EmptyLayer {
    var body: some View {
        content
            .onChange(of: date) { newDate in
                load(for: newDate)
            }
            .onReceive(didAddMeal, perform: animateMealInsertionOrRemoval)
            .onReceive(didDeleteMeal, perform: animateMealInsertionOrRemoval)
            .onReceive(initialSyncCompleted, perform: initialSyncCompleted)
            .onReceive(shouldRefreshDay, perform: shouldRefreshDay)
            .confirmationDialog(
                dropConfirmationTitle,
                isPresented: $showingDropOptions,
                titleVisibility: .visible,
                actions: dropConfirmationActions
            )
            .onChange(of: showingDropOptions) { newValue in
                if !newValue {
                    droppedItem = nil
                }
            }
    }
    
    func shouldRefreshDay(_ notification: Notification) {
        cprint("↔️ shouldRefreshDay → DayView.Empty — animatingMeal = true")
        animatingMeal = true
        reload()
    }
    
    func initialSyncCompleted(_ notification: Notification) {
        cprint("↔️ initialSyncCompleted → DayView.Empty — animatingMeal = true")
        animatingMeal = true
        reload()
    }
    
    func animateMealInsertionOrRemoval(_ notification: Notification) {
        cprint("↔️ animateMealInsertionOrRemoval → DayView.Empty — animatingMeal = true")
        animatingMeal = true
        reload()
    }

    func reload() {
        load(for: date)
    }
    
    func load(for date: Date) {
        let current = DataManager.shared.isDateEmpty(date)
        
        /// Removed this for now as having it stopped empty views from animating their transition between each other
        /// **This is now causing issues when**
        /// [ ] adding first meal to a day and transitioning away immediately (waiting a while doesn't cause it)
        /// [ ] deleting last meal to a day and waiting for a few seconds
//        guard currentShowingEmpty != current else {
//            print("↔️ DayView.Empty.load() — animatingMeal = false")
//            animatingMeal = false
//            return
//        }
        /// Replaced previous check with this to stop transitions when deleting and adding only meal on day`
        if currentShowingEmpty == current, previousDate == date {
            animatingMeal = false
            return
        }
        
        cprint("↔️🈸 load(for: \(date.calendarDayString)) – previousDate \(previousDate.calendarDayString)")
        cprint("↔️🈸     - previousShowingEmpty: \(previousShowingEmpty) → \(self.currentShowingEmpty)")
        cprint("↔️🈸     - currentShowingEmpty: \(currentShowingEmpty) → false")
        self.previousShowingEmpty = self.currentShowingEmpty
        self.currentShowingEmpty = false
        
        withAnimation {
            cprint("↔️🈸     (Animating)")
            cprint("↔️🈸       - currentShowingEmpty: \(currentShowingEmpty) → \(current)")
            cprint("↔️🈸       - previousShowingEmpty: \(previousShowingEmpty) → false")
            self.currentShowingEmpty = current
            self.previousShowingEmpty = false
        }
        self.previousDate = date
        cprint("↔️ DayView.Empty.load() — animatingMeal = false")
        animatingMeal = false
    }
    
    var transitioningForwards: Bool {
        date > previousDate
    }
    
    var content: some View {
        ZStack {
            previousContent
            currentContent
        }
        .dropDestination(
            for: DropItem.self,
            action: handleDrop,
            isTargeted: handleDropIsTargeted
        )
    }

    var previousContent: some View {
        var transition: AnyTransition {
            var edge: Edge {
                guard !animatingMeal else {
                    return .bottom
                }
                return transitioningForwards ? .leading : .trailing
            }
            
            cprint("🈸 Transitioning: \(edge)")
            return .move(edge: edge)
        }
        
        return Group {
            if previousShowingEmpty {
                DayView.EmptyMessage(
                    date: previousDate,
                    isTargetedForDrop: $isTargetedForDrop,
                    showingDropOptions: $showingDropOptions,
//                    shouldShowDropDestination: shouldShowDropDestinationBinding,
                    actionHandler: actionHandler
                )
                .frame(maxWidth: .infinity)
                .transition(transition)
            }
        }
    }
    
    var currentContent: some View {
        var transition: AnyTransition {
            var edge: Edge {
                guard !animatingMeal else {
                    return .bottom
                }

                return transitioningForwards ? .trailing : .leading
            }
            
            return .move(edge: edge)
        }

        return Group {
            if currentShowingEmpty {
                DayView.EmptyMessage(
                    date: date,
                    isTargetedForDrop: $isTargetedForDrop,
                    showingDropOptions: $showingDropOptions,
//                    shouldShowDropDestination: shouldShowDropDestinationBinding,
                    actionHandler: actionHandler
                )
                .frame(maxWidth: .infinity)
                .transition(transition)
            }
        }
    }
    
    //MARK: - Drop Related
    
    func handleDrop(_ items: [DropItem], location: CGPoint) -> Bool {
        showingDropOptions = true
        droppedItem = items.first
        return true
    }

    func handleDropIsTargeted(_ isTargeted: Bool) {
        Haptics.selectionFeedback()
        withAnimation {
            isTargetedForDrop = isTargeted
        }
    }
    
    var dropConfirmationTitle: String {
        guard let droppedItem else { return "" }
        return droppedItem.description
    }
    
    @ViewBuilder
    func dropConfirmationActions() -> some View {
        Button("Move") {
            guard let droppedItem else { return }
            switch droppedItem {
            case .meal(let meal):
                animatingMeal = true
                withAnimation {
                    previousShowingEmpty = false
                    currentShowingEmpty = false
                }
                viewModel.moveMeal(meal)
                break
            case .foodItem(let foodItem):
                break
            default:
                break
            }
        }
        Button("Duplicate") {
            guard let droppedItem else { return }
            switch droppedItem {
            case .meal(let meal):
                animatingMeal = true
                withAnimation {
                    previousShowingEmpty = false
                    currentShowingEmpty = false
                }
                viewModel.copyMeal(meal)
                break
            case .foodItem(let foodItem):
                break
            default:
                break
            }
        }
    }
}

//MARK: - DayView.EmptyMessage

extension DayView {
    struct EmptyMessage: View {
        @Environment(\.colorScheme) var colorScheme
        let date: Date
        @State var markedAsFasted = false
        
        @State var messageSize: CGSize = .zero
        
        let actionHandler: (LogAction) -> ()
        
        @Binding var isTargetedForDrop: Bool
        @Binding var showingDropOptions: Bool
        @State var animatedShowDropDestination: Bool = false

        init(
            date: Date,
            isTargetedForDrop: Binding<Bool>,
            showingDropOptions: Binding<Bool>,
            actionHandler: @escaping (LogAction) -> ()
        ) {
            _isTargetedForDrop = isTargetedForDrop
            _showingDropOptions = showingDropOptions
            self.date = date
            self.actionHandler = actionHandler
        }
    }
}

extension DayView.EmptyMessage {
    @ViewBuilder
    var body: some View {
        ZStack {
            background
            emptyMessageLayer
        }
        /// This is essential to make sure it doesn't shift vertically when we're resigning focus from the
        /// proxy text field (which we use to mitigate the tap target movement bug with sheets)
        .ignoresSafeArea(.keyboard)
        .onChange(of: isTargetedForDrop, perform: isTargetedForDropChanged)
        .onChange(of: showingDropOptions, perform: showingDropOptionsChanged)
    }
    
    func isTargetedForDropChanged(_ newValue: Bool) {
        /// Delay the hiding of the drop destination slightly when `isTargetedForDrop` becomes `false`,
        /// to account for the slight gap in time between it becoming `false` and the `showingDropOptions` being set to `true`.
        /// This removes the sudden flash of the drop target disappearing and then reappearing when we release our finger.
        DispatchQueue.main.asyncAfter(deadline: .now() + (newValue ? 0 : 0.5)) {
            withAnimation(.interactiveSpring()) {
                self.animatedShowDropDestination = isTargetedForDrop || showingDropOptions
            }
        }
    }
    
    func showingDropOptionsChanged(_ newValue: Bool) {
        withAnimation(.interactiveSpring()) {
            self.animatedShowDropDestination = isTargetedForDrop || showingDropOptions
        }
    }
    
    func shouldShowDropDestination(_ newValue: Bool) {
        withAnimation(.interactiveSpring()) {
            self.animatedShowDropDestination = newValue
        }
    }
    
    var background: Color {
        colorScheme == .light ? Color(.systemGroupedBackground) : Color(hex: "191919")
    }
    
    var emptyMessageLayer: some View {
        VStack {
            Spacer()
            ZStack {
//                emptyMessage
//                    .blur(radius: isTargetedForDrop ? 2.0 : 0)
//                    .readSize { size in
//                        messageSize = size
//                    }
                if animatedShowDropDestination {
                    dropTargetView
                } else {
                    emptyMessage
                        .readSize { size in
                            messageSize = size
                        }
                }
            }
            Spacer()
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    var dropTargetView: some View {
        Text("Move or Duplicate Here")
            .bold()
            .foregroundColor(.primary)
//            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .frame(height: messageSize.height)
            .padding(.horizontal, 20)
            .padding(.horizontal, 50)
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
            .opacity(0.8)
    }
    
    var emptyString: String {
        date.isBeforeToday
        ? "No meals were logged on this day"
        : "You haven't prepped any meals yet"
    }
    
    var emptyMessage: some View {
        HStack {
            Spacer()
            VStack {
                Text(emptyString)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(.tertiaryLabel))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
                addMealEmptyButton
                markAsFastedSection
            }
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .foregroundColor(Color(.quaternarySystemFill).opacity(colorScheme == .dark ? 0.5 : 1.0))
            )
            .padding(.horizontal, 50)
            Spacer()
        }
    }
    
    @ViewBuilder
    var markAsFastedSection: some View {
        if showFastedSection {
            VStack {
                Toggle("Log as Fasted", isOn: $markedAsFasted)
                    .tint(Color.accentColor.gradient)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(Color(.quaternarySystemFill))
                    )
                explanationText
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.footnote)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }


    func markedAsFastedChanged(_ newValue: Bool) {
        DataManager.shared.setFastedState(as: newValue, on: date)
    }

    var addMealEmptyButton: some View {
        let string = date.isBeforeToday ? "Log a Meal" : "Prep a Meal"
        
        var label: some View {
            HStack {
                Image(systemName: "note.text.badge.plus")
                Text(string)
                    .fontWeight(.bold)
            }
            .foregroundColor(.accentColor)
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(
                        colorScheme == .dark ? 0.1 : 0.15
                    ))
            )
        }
        
        var button: some View {
            Button {
                actionHandler(.addMeal(nil))
            } label: {
                label
            }
            .buttonStyle(.borderless)
        }
        
        var customButton: some View {
            label
                .onTapGesture {
                    actionHandler(.addMeal(nil))
                }
        }
        
        return button
    }
    
    func yOffset(forHeight contentHeight: CGFloat, safeAreaInsets: EdgeInsets) -> CGFloat {
        let topHeight: CGFloat = 185

        let bottomHeight: CGFloat = 95

        return (UIScreen.main.bounds.height - topHeight - bottomHeight) / 2.0 - (contentHeight / 2.0)
    }
    
    var showFastedSection: Bool {
        date.startOfDay < Date().startOfDay
    }
    
    @ViewBuilder
    var explanationText: some View {
        markedAsFasted
        ? Text("Logging this day as fasted will ensure it is included in your daily averages and total fasted time.")
        : Text("If you do not have this set, you will not be logging this day and it will not affect your daily averages or count towards your fasted duration.")
    }
}

extension Date {
    var isBeforeToday: Bool {
        startOfDay < Date().startOfDay
    }
}
