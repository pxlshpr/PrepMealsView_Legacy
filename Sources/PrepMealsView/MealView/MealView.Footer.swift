import SwiftUI
import SwiftHaptics
import PrepDataTypes

extension MealView {
    struct Footer: View {
        //TODO: CoreData
//        @ObservedObject var meal: Meal
        var meal: Meal
    }
}

extension MealView.Footer {
    var body: some View {
        content
        .listRowBackground(
            ListRowBackground(
                includeTopSeparator: true
            )
        )
        .listRowInsets(.none)
        .listRowSeparator(.hidden)
    }
    
    var content: some View {
        HStack(spacing: 0) {
            if !meal.isCompleted {
                addFoodButton
            }
            Spacer()
            if !meal.foodItems.isEmpty {
                energyButton
            }
        }
    }
    
    var addFoodButton: some View {
        Button {
            tappedAddFood()
        } label: {
            Group {
                if meal.foodItems.isEmpty {
                    Image(systemName: "plus")
//                    Text("Add Food")
                } else {
                    Text("Add Food")
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.trailing)
        .buttonStyle(.borderless)
        .frame(maxHeight: .infinity)
    }

    var energyButton: some View {
        Button {
            tappedEnergy()
        } label: {
            Text("\(Int(meal.energyAmount)) kcal")
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel))
        }
        .contentShape(Rectangle())
        .padding(.leading)
        .buttonStyle(.borderless)
        .frame(maxHeight: .infinity)
    }
    
    //MARK: - Actions
    func tappedAddFood() {
        //TODO: Callback for this
        Haptics.feedback(style: .soft)
    }
    
    func tappedEnergy() {
        //TODO: Callback for this
        Haptics.feedback(style: .soft)
    }
}

struct ListPagerPreview: View {
    @Namespace var namespace
    
    var body: some View {
        NavigationView {
            listPage
                .navigationTitle("List Page")
        }
    }
    
    var listPage: some View {
        ListPage(getMealsHandler: { date in
            meals
        }, tapAddMealHandler: {
        }, namespace: namespace)
    }
    
    var meals: [Meal] {
        [
            mockMeal("Breakfast", at: Date()),
            mockMeal("Lunch", at: Date()),
            mockMeal("Dinner", at: Date())
        ]
    }
    
    func mockMeal(_ name: String, at time: Date) -> Meal {
        Meal(id: UUID(), day: day,
             name: name,
             time: Date().timeIntervalSince1970,
             markedAsEatenAt: 0,
             foodItems: [],
             syncStatus: .notSynced, updatedAt: 0)
    }
    
    var day: Day {
        Day(id: "day", calendarDayString: "", addEnergyExpendituresToGoal: false, energyExpenditures: [], meals: [], syncStatus: .notSynced, updatedAt: 0)
    }
}

struct ListPager_Previews: PreviewProvider {
    static var previews: some View {
        ListPagerPreview()
    }
}
