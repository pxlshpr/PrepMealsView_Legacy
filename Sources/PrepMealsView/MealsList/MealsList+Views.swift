import SwiftUI
import SwiftHaptics

extension MealsList {

    var list: some View {
        List {
            ForEach(meals) { meal in
                Meal(meal: meal)
            }
            quickAddButtons
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }
    
    //MARK: - Buttons
    
    var addMealButton: some View {
        Button {
            onTapAddMeal(nil)
            Haptics.feedback(style: .soft)
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
        Section {
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
        .listRowBackground(
            ZStack {
                ListRowBackground(
                    color: Color(.systemGroupedBackground),
                    includeTopSeparator: false,
                    includeBottomSeparator: false,
                    includeTopPadding: true
                )
            }
        )
        .listRowSeparator(.hidden)
    }
    
    func quickAddButton(at time: Date? = nil) -> some View {
        Button {
            onTapAddMeal(time ?? Date())
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
