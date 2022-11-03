import SwiftUI
import SwiftHaptics
import SwiftUISugar
import PrepDataTypes

extension MealView {
    struct Header: View {
        
        @Environment(\.colorScheme) var colorScheme
        @ObservedObject var viewModel: ViewModel
        var meal: DayMeal

//        @Namespace var localNamespace
//        var namespace: Binding<Namespace.ID?>
//        @Binding var namespacePrefix: UUID
    }
}

extension MealView.Header {
    
    var body: some View {
//        let _ = Self._printChanges()
        return content
        .listRowBackground(
            ListRowBackground(
                includeBottomSeparator: !meal.foodItems.isEmpty
            )
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
//                            .if(namespace.wrappedValue != nil) { view in
//                                view.matchedGeometryEffect(id: "date-\(viewModel.animationID)-\(namespacePrefix.uuidString)", in: namespace.wrappedValue!)
//                            }
//                            .if(namespace.wrappedValue == nil) { view in
//                                view.matchedGeometryEffect(id: "date-\(viewModel.animationID)-\(namespacePrefix.uuidString)", in: localNamespace)
//                            }
                        Text("•")
                        Text(viewModel.meal.name)
//                            .if(namespace.wrappedValue != nil) { view in
//                                view.matchedGeometryEffect(id: "\(viewModel.animationID)-\(namespacePrefix.uuidString)", in: namespace.wrappedValue!)
//                            }
//                            .if(namespace.wrappedValue == nil) { view in
//                                view.matchedGeometryEffect(id: "\(viewModel.animationID)-\(namespacePrefix.uuidString)", in: localNamespace)
//                            }
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
