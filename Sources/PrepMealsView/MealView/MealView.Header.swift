import SwiftUI
import SwiftHaptics
import SwiftUISugar

extension MealView {
    struct Header: View {
        @Environment(\.colorScheme) var colorScheme
        @ObservedObject var viewModel: ViewModel
        
        let namespace: Namespace.ID
    }
}

extension MealView.Header {
    var body: some View {
        content
        .listRowBackground(
            ListRowBackground(includeBottomSeparator: true)
        )
        .listRowSeparator(.hidden)
    }
    
    var content: some View {
        HStack {
            Button {
                tappedEditMeal()
            } label: {
                Group {
                    HStack {
                        Text("**\(viewModel.meal.timeString)**")
                            .matchedGeometryEffect(id: "date-\(viewModel.animationID)", in: namespace)
                        Text("•")
                        Text(viewModel.meal.name)
                            .matchedGeometryEffect(id: viewModel.animationID, in: namespace)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
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
                .textCase(.uppercase)
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel))
            }
            .buttonStyle(.plain)
            Spacer()
            mealMenu
        }
    }
    
    //MARK: - Menu
    
    var mealMenu: some View {
        Menu {
            if viewModel.shouldShowAddFoodActionInMenu {
                addFoodMenuButton
            }
            if viewModel.shouldShowCompleteActionInMenu {
                completeButton
            }
            deleteButton
        } label: {
            Image(systemName: "ellipsis")
                .padding(.top, 10)
                .padding(.bottom, 5)
                .padding(.leading)
        }
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
