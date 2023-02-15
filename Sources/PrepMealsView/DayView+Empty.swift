import SwiftUI
import PrepDataTypes
import PrepCoreDataStack

//MARK: - DayView.EmptyLayer

extension DayView {
    struct EmptyLayer: View {
        @Binding var date: Date
        @State var previousDate: Date = Date()
        
        @State var previousShowingEmpty: Bool = false
        @State var currentShowingEmpty: Bool = true
    }
}

extension DayView.EmptyLayer {
    var body: some View {
        content
            .onChange(of: date) { newDate in
                let current = DataManager.shared.isDateEmpty(newDate)
                self.previousShowingEmpty = self.currentShowingEmpty
                self.currentShowingEmpty = false
                withAnimation {
                    self.currentShowingEmpty = current
                    self.previousShowingEmpty = false
                }
                self.previousDate = date
            }
    }
    
    var transitioningForwards: Bool {
        date > previousDate
    }
    
    var content: some View {
        ZStack {
            previousContent
            currentContent
        }
    }
    
    var previousContent: some View {
        var transition: AnyTransition {
            var edge: Edge {
                transitioningForwards ? .leading : .trailing
            }
            print("Edge for previous transition: \(edge)")
            return .move(edge: edge)
        }
        return Group {
            if previousShowingEmpty {
                DayView.EmptyMessage(date: previousDate)
//                Text("Previous")
                    .frame(maxWidth: .infinity)
                    .transition(transition)
            }
        }
    }
    
    var currentContent: some View {
        var transition: AnyTransition {
            var edge: Edge {
                transitioningForwards ? .trailing : .leading
            }
            print("🗡 Edge for current transition: \(edge), while date is: \(date.calendarDayString)")
            return .move(edge: edge)
        }

        return Group {
            if currentShowingEmpty {
                DayView.EmptyMessage(date: date)
//                Text("Current")
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
        
        init(date: Date) {
            self.date = date
        }
    }
}

extension DayView.EmptyMessage {
    @ViewBuilder
    var body: some View {
        optionalBody
    }
    
    var optionalBody: some View {
        ZStack {
            background
            emptyMessageLayer
//                .padding(.bottom, PrepConstants.bottomBarHeight / 2.0)
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
            emptyMessage
            Spacer()
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    var emptyMessage: some View {
        content
    }
    
    var emptyString: String {
        date.isBeforeToday
        ? "No meals were logged on this day"
        : "You haven't prepped any meals yet"
    }
    
    var content: some View {
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
//                actionHandler(.addMeal(nil))
            } label: {
                label
            }
            .buttonStyle(.borderless)
        }
        
        var customButton: some View {
            label
                .onTapGesture {
//                    actionHandler(.addMeal(nil))
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
