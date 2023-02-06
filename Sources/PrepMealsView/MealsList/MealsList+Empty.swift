import SwiftUI
import PrepCoreDataStack

extension MealsList {

    var emptyContent_legacy: some View {
        var emptyMessageLayer: some View {
            
            func yOffset(forHeight contentHeight: CGFloat, safeAreaInsets: EdgeInsets) -> CGFloat {
                /// [ ] Handle these hardcoded values gracefully
//                let weekPagerHeight: CGFloat = 45
//                let dayPagerHeight: CGFloat = 27
//                let topHeight: CGFloat = weekPagerHeight + dayPagerHeight + safeAreaInsets.top
                let topHeight: CGFloat = 185

                let bottomHeight: CGFloat = 95

                return (UIScreen.main.bounds.height - topHeight - bottomHeight) / 2.0 - (contentHeight / 2.0)
            }
            
            var showFastedSection: Bool {
                date.startOfDay < Date().startOfDay
            }
            
            var emptyMessage: some View {
                GeometryReader { proxy in
                    content
                        .readSize { size in
                            emptyContentHeight = size.height
                        }
                        .offset(y: yOffset(forHeight: emptyContentHeight, safeAreaInsets: proxy.safeAreaInsets))
                }
            }
            
            var content: some View {

                HStack {
                    Spacer()
                    VStack {
//                        Text(emptyText + " " + date.calendarDayString + " \(markedAsFasted)")
                        Text(emptyText)
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
                .transition(.opacity)
            }
            
            @ViewBuilder
            var markAsFastedSection: some View {
                if showFastedSection {
                    VStack {
                        Toggle("Mark as fasted", isOn: markedAsFastedBinding)
                            .tint(Color.accentColor.gradient)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(Color(.quaternarySystemFill))
                            )
//
//                        Toggle("Mark as fasted", isOn: markedAsFastedBinding)
//                            .toggleStyle(.button)
//                            .padding(.horizontal, 20)
//                            .padding(.vertical, 10)
//                            .background(
//                                RoundedRectangle(cornerRadius: 15, style: .continuous)
//                                    .fill(Color(.quaternarySystemFill))
//                            )
                        Text("This day is being counted as zero calories, affecting your daily averages.")
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.footnote)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            
            return ScrollView {
                VStack {
                    Spacer()
                    emptyMessage
                    Spacer()
                }
            }
        }
        
        return ZStack {
            background
            emptyMessageLayer
        }
    }

    var emptyContent: some View {
        var emptyMessageLayer: some View {
            
            func yOffset(forHeight contentHeight: CGFloat, safeAreaInsets: EdgeInsets) -> CGFloat {
                /// [ ] Handle these hardcoded values gracefully
//                let weekPagerHeight: CGFloat = 45
//                let dayPagerHeight: CGFloat = 27
//                let topHeight: CGFloat = weekPagerHeight + dayPagerHeight + safeAreaInsets.top
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
                ? Text("This day **is** included when calculating your daily averages.")
                : Text("This day is **not** included when calculating your daily averages.")
            }
            
            var emptyMessage: some View {
                content
                    .readSize { size in
                        emptyContentHeight = size.height
                    }
            }
            
            var content: some View {

                HStack {
                    Spacer()
                    VStack {
//                        Text(emptyText + " " + date.calendarDayString + " \(markedAsFasted)")
                        Text(emptyText)
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
                .transition(.opacity)
            }
            
            @ViewBuilder
            var markAsFastedSection: some View {
                if showFastedSection {
                    VStack {
                        Toggle("Mark as fasted", isOn: markedAsFastedBinding)
                            .tint(Color.accentColor.gradient)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(Color(.quaternarySystemFill))
                            )
//                        Toggle("Mark as fasted", isOn: markedAsFastedBinding)
//                            .toggleStyle(.button)
//                            .padding(.horizontal, 20)
//                            .padding(.vertical, 10)
//                            .background(
//                                RoundedRectangle(cornerRadius: 15, style: .continuous)
//                                    .fill(Color(.quaternarySystemFill))
//                            )
                        explanationText
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.footnote)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            
            return VStack {
                Spacer()
                emptyMessage
                Spacer()
            }
        }
        
        return ZStack {
            background
            emptyMessageLayer
        }
    }

    func markedAsFastedChanged(_ newValue: Bool) {
        DataManager.shared.setFastedState(as: newValue, on: date)
    }

    var addMealEmptyButton: some View {
        let string = isBeforeToday ? "Log a Meal" : "Prep a Meal"
        
        var label: some View {
            HStack {
                Image(systemName: "note.text.badge.plus")
                Text(string)
                    .fontWeight(.bold)
            }
//            .foregroundColor(colorScheme == .light ? Color(.secondarySystemGroupedBackground) : .accentColor)
            .foregroundColor(.accentColor)
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(
                        colorScheme == .dark ? 0.1 : 0.15
                    ))
            )
            
//            .background(
//                RoundedRectangle(cornerRadius: 20, style: .continuous)
////                    .foregroundStyle(colorScheme == .light ? .regularMaterial : .ultraThinMaterial)
//                    .foregroundColor(colorScheme == .light ? Color.accentColor : Color(hex: "343435"))
//            )
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
}

struct MealsListEmptyPreview: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Text("You haven't prepped any meals yet")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(.tertiaryLabel))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
                addMealEmptyButton
            }
            .frame(width: UIScreen.main.bounds.width * 0.7, height: 170)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .foregroundColor(Color(.quaternarySystemFill).opacity(colorScheme == .dark ? 0.5 : 1.0))
            )
            .padding(.horizontal, 50)
            Spacer()
        }
    }
    
    var addMealEmptyButton: some View {
        var label: some View {
            HStack {
                Image(systemName: "note.text.badge.plus")
                Text("Prep a Meal")
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
            } label: {
                label
            }
            .buttonStyle(.borderless)
        }
        
        return button
    }
}

struct MealsListEmpty_Previews: PreviewProvider {
    static var previews: some View {
        MealsListEmptyPreview()
    }
}
