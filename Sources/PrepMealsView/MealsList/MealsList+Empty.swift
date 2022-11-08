import SwiftUI

extension MealsList {

    var emptyContent: some View {
        ZStack {
            Color(.systemGroupedBackground)
            VStack {
                Text(emptyText)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(.tertiaryLabel))
                addMealEmptyButton
            }
            .padding()
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .foregroundColor(Color(.quaternarySystemFill))
            )
            .padding(.horizontal, 50)
            .offset(y: 0)
        }
    }
    
    var addMealEmptyButton: some View {
        let string = isBeforeToday ? "Log a Meal" : "Prep a Meal"
        return Button {
            onTapAddMeal(nil)
        } label: {
            HStack {
                Image(systemName: "note.text.badge.plus")
                Text(string)
            }
            .foregroundColor(.white)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
//                Capsule(style: .continuous)
                    .foregroundColor(Color.accentColor)
            )
        }
        .buttonStyle(.borderless)
    }
}

struct MealsListEmptyPreview: View {
    var body: some View {
        MealsList(date: Date(),
                  meals: .constant([]),
                  didTapAddFood: { _ in },
                  onTapAddMeal: { _ in })
    }
}

struct MealsListEmpty_Previews: PreviewProvider {
    static var previews: some View {
        MealsListEmptyPreview()
    }
}
