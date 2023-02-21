import SwiftUI
import PrepDataTypes
import PrepCoreDataStack
import SwiftHaptics

//MARK: - DayView.EmptyLayer

extension DayView {
    struct EmptyLayer: View {
        @Environment(\.colorScheme) var colorScheme
        @Binding var date: Date
        let actionHandler: (LogAction) -> ()

        @State var previousDate: Date = Date()
        @State var previousShowingEmpty: Bool = false
        @State var currentShowingEmpty: Bool = true
        @State var animatingMeal: Bool = false
        
        @State var isTargetedForDrop: Bool = false
        
        let shouldRefreshDay = NotificationCenter.default.publisher(for: .shouldRefreshDay)
        let didAddMeal = NotificationCenter.default.publisher(for: .didAddMeal)
        let didDeleteMeal = NotificationCenter.default.publisher(for: .didDeleteMeal)
        let initialSyncCompleted = NotificationCenter.default.publisher(for: .initialSyncCompleted)
        
        init(date: Binding<Date>, actionHandler: @escaping (LogAction) -> (), initialShowingEmpty: Bool = false) {
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
    }
    
    func shouldRefreshDay(_ notification: Notification) {
        animatingMeal = true
        reload()
    }
    
    func initialSyncCompleted(_ notification: Notification) {
        animatingMeal = true
        reload()
    }
    
    func animateMealInsertionOrRemoval(_ notification: Notification) {
        animatingMeal = true
        reload()
    }

    func reload() {
        load(for: date)
    }
    
    func load(for date: Date) {
        let current = DataManager.shared.isDateEmpty(date)
        
        guard currentShowingEmpty != current else {
            return
        }
        
        self.previousShowingEmpty = self.currentShowingEmpty
        self.currentShowingEmpty = false
        withAnimation {
            self.currentShowingEmpty = current
            self.previousShowingEmpty = false
        }
        self.previousDate = date
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
            for: MealFoodItem.self,
            action: { items, location in
                return true
            }, isTargeted: { isTargeted in
                Haptics.selectionFeedback()
                withAnimation {
                    isTargetedForDrop = isTargeted
                }
            })
    }
    
    var previousContent: some View {
        var transition: AnyTransition {
            var edge: Edge {
                guard !animatingMeal else {
                    return .bottom
                }
                return transitioningForwards ? .leading : .trailing
            }
            
            return .move(edge: edge)
        }
        
        return Group {
            if previousShowingEmpty {
                DayView.EmptyMessage(date: previousDate, isTargetedForDrop: $isTargetedForDrop, actionHandler: actionHandler)
//                Text("Previous")
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
                    actionHandler: actionHandler
                )
                .frame(maxWidth: .infinity)
                .transition(transition)
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

        init(date: Date, isTargetedForDrop: Binding<Bool>, actionHandler: @escaping (LogAction) -> ()) {
            _isTargetedForDrop = isTargetedForDrop
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
                if isTargetedForDrop {
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
        Text("Drop food here")
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
