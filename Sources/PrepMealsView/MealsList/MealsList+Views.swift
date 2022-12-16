import SwiftUI
import SwiftHaptics

extension MealsList {

    var list: some View {
        List {
            ForEach(meals) { meal in
                Meal(
                    date: date,
                    meal: meal,
                    meals: meals,
                    actionHandler: actionHandler
//                    didTapAddFood: didTapAddFood,
//                    didTapEditMeal: didTapEditMeal,
//                    didTapMealFoodItem: didTapMealFoodItem
                )
            }
            quickAddButtons
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }
    
    var scrollView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
                ForEach(meals) { meal in
                    Meal(
                        date: date,
                        meal: meal,
                        meals: meals,
                        actionHandler: actionHandler
//                        didTapAddFood: didTapAddFood,
//                        didTapEditMeal: didTapEditMeal,
//                        didTapMealFoodItem: didTapMealFoodItem
                    )
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
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .foregroundColor(Color(.tertiarySystemFill))
            )
        }
        .buttonStyle(.borderless)
    }

    var quickAddButtons: some View {
        
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
        Button {
            actionHandler(.addMeal(time ?? Date()))
//            onTapAddMeal(time ?? Date())
            Haptics.successFeedback()
        } label: {
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
        .buttonStyle(.borderless)
    }
}
