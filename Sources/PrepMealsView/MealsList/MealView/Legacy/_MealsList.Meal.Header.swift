//import SwiftUI
//import SwiftHaptics
//import SwiftUISugar
//import PrepDataTypes
//import PrepCoreDataStack
//
//extension MealsList.Meal {
//    
//    struct Header: View {
//        @EnvironmentObject var viewModel: ViewModel
//        @Environment(\.colorScheme) var colorScheme
//    }
//}
//
//extension MealsList.Meal.Header {
//    
//    var body: some View {
//        content
//        .listRowBackground(listRowBackground)
//        .listRowSeparator(.hidden)
//    }
//    
//    var listRowBackground: some View {
//        let includeBottomSeparator = Binding<Bool>(
//            get: { !viewModel.meal.foodItems.isEmpty },
//            set: { _ in }
//        )
//        return ListRowBackground(includeBottomSeparator: includeBottomSeparator)
//    }
//    
//    var content: some View {
//        HStack {
//            Button {
//                tappedEditMeal()
//            } label: {
//                Group {
//                    HStack {
//                        Text("**\(viewModel.meal.timeString)**")
//                        Text("•")
//                        Text(viewModel.meal.name)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .fixedSize(horizontal: false, vertical: true)
//                    }
//                    if viewModel.shouldShowUpcomingLabel {
//                        Text("UPCOMING")
//                            .foregroundColor(.white)
////                            .font(.footnote)
//                            .padding(.vertical, 3)
//                            .padding(.horizontal, 5)
//                            .background(
//                                RoundedRectangle(cornerRadius: 4)
//                                    .foregroundColor(Color.accentColor)
//                            )
//                    }
//                }
//                .textCase(.uppercase)
//                .font(.footnote)
//                .foregroundColor(Color(.secondaryLabel))
//            }
//            .buttonStyle(.plain)
//            Spacer()
//            mealMenuButton
//        }
//    }
//    
//    //MARK: - Menu
//    
//    var mealMenuButton: some View {
//        Menu {
//            Button {
//                
//            } label: {
//                Label("Add Food", systemImage: "plus")
//            }
//
//            Button {
//                
//            } label: {
//                Label("Mark as Eaten", systemImage: "checkmark.circle")
//            }
//
//            
//            Divider()
//
//            
//            Button {
//                
//            } label: {
//                Label("Summary", systemImage: "chart.bar.xaxis")
//            }
//
//            Button {
//                
//            } label: {
//                Label("Food Label", systemImage: "chart.bar.doc.horizontal")
//            }
//            
//
//            Divider()
//
//            
//            Button {
//                
//            } label: {
//                Label("Edit", systemImage: "pencil")
//            }
//
//            Button(role: .destructive) {
//                do {
//                    try DataManager.shared.deleteMeal(viewModel.meal)
//                } catch {
//                    cprint("Couldn't delete meal: \(error)")
//                }
//            } label: {
//                Label("Delete", systemImage: "trash")
//            }
//            
//        } label: {
//            Image(systemName: "ellipsis")
//                .foregroundColor(.accentColor)
//                .padding(.top, 10)
//                .padding(.bottom, 5)
//                .padding(.leading)
//        }
//        .contentShape(Rectangle())
//        .simultaneousGesture(TapGesture().onEnded {
//            Haptics.feedback(style: .soft)
//        })
//    }
//    
//    var addFoodMenuButton: some View {
//        Button {
//            tappedAddFood()
//        } label: {
//            Label("Add food", systemImage: "plus")
//                .textCase(.none)
//        }
//    }
//    var completeButton: some View {
//        Button {
//            withAnimation {
//                viewModel.tappedComplete()
//            }
//            Haptics.feedback(style: .soft)
//        } label: {
//            Label("Mark all foods as eaten", systemImage: "checkmark.circle")
//                .textCase(.none)
//        }
//    }
//    
//    var deleteButton: some View {
//        Button(role: .destructive) {
//            tappedDeleteMeal()
//        } label: {
//            Label(viewModel.deleteString, systemImage: "trash.fill")
//                .textCase(.none)
//        }
//    }
//    
//    //MARK: - Actions
//    
//    func tappedEditMeal() {
//        //TODO: Preset Edit Meal
//        Haptics.feedback(style: .light)
//    }
//    
//    func tappedAddFood() {
//        Haptics.feedback(style: .light)
//        //TODO: Present Meal
//    }
//    
//    func tappedDeleteMeal() {
//        Haptics.feedback(style: .rigid)
//        viewModel.tappedDelete()
//    }
//
//}
