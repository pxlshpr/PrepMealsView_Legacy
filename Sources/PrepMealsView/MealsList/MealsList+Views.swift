import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension MealsList {
    
    var scrollView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
                ForEach(meals) { meal in
                    mealView(for: meal)
                }
                quickAddButtons
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: 60 + 55)
                    }
            }
        }
//        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(background)
//        .onAppear {
//            DispatchQueue.main.async {
//                self.animation = .none
//            }
//        }
    }
    
    func mealView(for meal: DayMeal) -> some View {
        let isUpcomingMealBinding = Binding<Bool>(
            get: {
                guard date.isToday, let nextPlannedMeal = meals.nextPlannedMeal else {
                    return false
                }
                return nextPlannedMeal.id == meal.id
            },
            set: { _ in }
        )
        return Meal(
            date: date,
            meal: meal,
            badgeWidths: $badgeWidths,
            isUpcomingMeal: isUpcomingMealBinding,
            actionHandler: actionHandler
        )
    }
    
    var background: Color {
        colorScheme == .light ? Color(.systemGroupedBackground) : Color(hex: "191919")
    }
    
    //MARK: - Buttons
    
    var addMealButton: some View {
        Button {
            actionHandler(.addMeal(nil))
//            onTapAddMeal(nil)
//            Haptics.feedback(style: .soft)
        } label: {
            HStack {
                Image(systemName: "note.text.badge.plus")
                Text("Add Meal")
                    .bold()
            }
            .font(.footnote)
            .padding(.horizontal, 8)
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
//                    .fill(colorScheme == .light ? Color(hex: "DFDDF8") : Color(hex: "262335"))
                    .fill(Color.accentColor.opacity(
                        colorScheme == .dark ? 0.1 : 0.15
                    ))
            )
//            .background(
//                RoundedRectangle(cornerRadius: 15, style: .continuous)
//                    .foregroundColor(Color(.tertiarySystemFill))
//            )
        }
        .buttonStyle(.borderless)
    }

    var quickAddButtons: some View {
        
        var quickMealLabel: some View {
            Text("Quick:")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.leading, 5)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.secondary.opacity(
                            colorScheme == .dark ? 0.1 : 0.15
                        ))
                        .opacity(0)
                )

        }
        
        var row: some View {
            var gradientFill: LinearGradient {
                var backgroundColor: Color {
//                    colorScheme == .light ? Color(hex: "F2F2F7") : Color(hex: "191919")
                    colorScheme == .light ? Color(hex: "EAEAF0") : Color(hex: "212122")
                }
                return LinearGradient(
                    gradient: Gradient(colors: [backgroundColor, .clear]), startPoint: .leading, endPoint: .trailing)
            }
            return HStack(spacing: 0) {
                addMealButton
                    .padding(.trailing, 5)
                quickMealLabel
                ZStack {
                    scrollView
                    HStack(spacing: 0) {
                        Rectangle()
//                            .fill(.blue.opacity(0.5))
                            .fill(gradientFill)
                            .frame(width: 20)
//                            .offset(x: -10)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.leading, 20)
        }
        
        var scrollView: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 5) {
                    if isToday {
                        quickAddButton()
                    }
                    ForEach(mealTimeSuggestions.indices, id: \.self) {
                        quickAddButton(at: mealTimeSuggestions[$0])
                    }
                }
                .padding(.horizontal, 10)
            }
        }
        
        return row
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 15)
            .background(
                Color(.quaternarySystemFill).opacity(colorScheme == .light ? 0.75 : 0.5)
                    .frame(height: 45)
            )
    }
   
    var quickAddButtons_legacy: some View {
        
        var listRowBackground: some View {
            ZStack {
                ListRowBackground(
                    color: .constant(Color(.systemGroupedBackground)),
                    includeTopSeparator: .constant(false),
                    includeBottomSeparator: .constant(false),
                    includeTopPadding: .constant(true)
                )
            }
        }
        
        return Section {
            HStack(spacing: 15) {
                addMealButton
                if isToday {
                    quickAddButton()
                }
                ForEach(mealTimeSuggestions.indices, id: \.self) {
                    quickAddButton(at: mealTimeSuggestions[$0])
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 15)
        .listRowBackground(listRowBackground)
        .listRowSeparator(.hidden)
    }
    
    func quickAddButton(at time: Date? = nil) -> some View {
        var label: some View {
            HStack {
                if let time {
                    Text(time.hourString.lowercased())
                } else {
                    Text("Now")
                }
            }
            .bold()
            .font(.footnote)
            .foregroundColor(.accentColor)
            .padding(.horizontal, 8)
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(
                        colorScheme == .dark ? 0.1 : 0.15
                    ))
            )
        }
        
        var label_legacy: some View {
            HStack {
                if let time {
                    Text(time.hourString)
                } else {
                    Text("Now")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .foregroundColor(Color(.tertiarySystemFill))
            )
        }
        
        return Button {
            actionHandler(.addMeal(time ?? Date()))
//            onTapAddMeal(time ?? Date())
            Haptics.successFeedback()
        } label: {
            label
        }
        .buttonStyle(.borderless)
    }
}
