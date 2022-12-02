import SwiftUI
import SwiftHaptics
import SwiftUISugar
import PrepDataTypes
import PrepCoreDataStack

extension MealsList.Meal {
    
    struct Header: View {
        @EnvironmentObject var viewModel: ViewModel
        @Environment(\.colorScheme) var colorScheme
    }
}

extension MealsList.Meal.Header {
    
    var body: some View {
        content
            .background(
                listRowBackground
            )
//            .listRowBackground(listRowBackground)
//            .listRowSeparator(.hidden)
    }
    
    var listRowBackground: some View {
        let includeBottomSeparator = Binding<Bool>(
            get: { !viewModel.meal.foodItems.isEmpty },
            set: { _ in }
        )
        return ListRowBackground(includeBottomSeparator: includeBottomSeparator)
    }
    
    var content: some View {
        HStack {
            titleButton
            Spacer()
            mealMenuButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    var titleButton: some View {
        var label: some View {
            
            @ViewBuilder
            var upcomingLabel: some View {
                if viewModel.shouldShowUpcomingLabel {
                    Text("UPCOMING")
                        .foregroundColor(.white)
                    //                            .font(.footnote)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .foregroundColor(Color.accentColor)
                        )
                }
            }
            
            var timeText: some View {
                Text("**\(viewModel.meal.timeString)**")
            }
            
            var separatorText: some View {
                Text("•")
            }
            var nameText: some View {
                Text(viewModel.meal.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            return Group {
                HStack {
                    timeText
                    separatorText
                    nameText
                }
                upcomingLabel
            }
            .textCase(.uppercase)
            .font(.footnote)
            .foregroundColor(Color(.secondaryLabel))
        }
        
        return Button {
            tappedEditMeal()
        } label: {
            label
        }
        .buttonStyle(.plain)
    }
    
    //MARK: - Menu
    
    var mealMenuButton: some View {
        Menu {
            Button {
                
            } label: {
                Label("Add Food", systemImage: "plus")
            }
            
            Button {
                
            } label: {
                Label("Mark as Eaten", systemImage: "checkmark.circle")
            }
            
            
            Divider()
            
            
            Button {
                
            } label: {
                Label("Summary", systemImage: "chart.bar.xaxis")
            }
            
            Button {
                
            } label: {
                Label("Food Label", systemImage: "chart.bar.doc.horizontal")
            }
            
            
            Divider()
            
            
            Button {
                
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                do {
                    try DataManager.shared.deleteMeal(viewModel.meal)
                } catch {
                    print("Couldn't delete meal: \(error)")
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
        } label: {
            Image(systemName: "ellipsis")
                .foregroundColor(.accentColor)
                .padding(.top, 10)
                .padding(.bottom, 5)
                .padding(.leading)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            Haptics.feedback(style: .soft)
        })
    }
    
    var addFoodMenuButton: some View {
        Button {
            tappedAddFood()
        } label: {
            Label("Add food", systemImage: "plus")
                .textCase(.none)
        }
    }
    var completeButton: some View {
        Button {
            withAnimation {
                viewModel.tappedComplete()
            }
            Haptics.feedback(style: .soft)
        } label: {
            Label("Mark all foods as eaten", systemImage: "checkmark.circle")
                .textCase(.none)
        }
    }
    
    var deleteButton: some View {
        Button(role: .destructive) {
            tappedDeleteMeal()
        } label: {
            Label(viewModel.deleteString, systemImage: "trash.fill")
                .textCase(.none)
        }
    }
    
    //MARK: - Actions
    
    func tappedEditMeal() {
        //TODO: Preset Edit Meal
        Haptics.feedback(style: .light)
    }
    
    func tappedAddFood() {
        Haptics.feedback(style: .light)
        //TODO: Present Meal
    }
    
    func tappedDeleteMeal() {
        Haptics.feedback(style: .rigid)
        viewModel.tappedDelete()
    }
    
}
