import SwiftUI
import SwiftHaptics
import PrepDataTypes
import SwiftUISugar
import FoodLabel
import PrepCoreDataStack

extension MealView {
    
    var headerView: some View {
        
        var listRowBackground: some View {
            let includeBottomSeparator = Binding<Bool>(
                get: {
                    !foodItems.isEmpty && !viewModel.targetingDropOverHeader
                },
                set: { _ in }
            )
            return ListRowBackground(includeBottomSeparator: includeBottomSeparator)
        }
        
        var menuButtonLayer: some View {
            HStack {
                Spacer()
                mealMenuButton
            }
            .frame(height: 44)
            .background(
                listRowBackground
            )
        }
        
        var titleButton: some View {
            var label: some View {
                
                @ViewBuilder
                var upcomingLabel: some View {
                    if viewModel.isUpcomingMeal {
                        Text("UPCOMING")
                            .foregroundColor(.white)
                            .font(.caption2)
                            .bold()
                            .padding(.vertical, 3)
                            .padding(.horizontal, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .foregroundColor(Color.accentColor)
                            )
                            .transition(.scale)
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
                
                var button: some View {
                    var label: some View {
                        HStack {
                            HStack {
                                timeText
                                separatorText
                                nameText
                            }
                            .fixedSize(horizontal: true, vertical: false)
                            upcomingLabel
                        }
                        .padding(.leading, 20)
                        .frame(height: 44)
                        .padding(.trailing, 20)
                        .draggable(viewModel.meal) {
                            MealView.DragPreview(meal: viewModel.meal)
                        }
                        .frame(maxHeight: .infinity)
                        .padding(.bottom, 16.75)
                        .contentShape(Rectangle())
                    }
                    
                    return Button {
                        tappedEditMeal()
                    } label: {
                        label
                    }
                    .buttonStyle(.plain)
                }
                
                return HStack {
                    button
    //                .background(.green)
                    Spacer()
                }
                .textCase(.uppercase)
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel))
            }
            
            var paddedLabel: some View {
                label
    //                .padding(.leading, 20)
    //                .frame(maxHeight: .infinity)
    //                .padding(.bottom, 16.75)
    //                .contentShape(Rectangle())
            }
            
            var button: some View {
                Button {
                    tappedEditMeal()
                } label: {
                    paddedLabel
                }
                .buttonStyle(.plain)
            }
            
            return button
    //        return paddedLabel
        }
        
        var titleButtonLayer: some View {
            HStack {
                titleButton
                Spacer()
            }
            .frame(height: 65)
        }
        
        return ZStack(alignment: .top) {
            menuButtonLayer
            titleButtonLayer
        }
    }
    
    var mealMenuButton: some View {
        var addFoodButton: some View {
            Button {
                viewModel.actionHandler(.addFood(viewModel.meal))
            } label: {
                Label("Add Food", systemImage: "plus")
            }
        }
        
        var mealCompletionButton: some View {
            var title: String {
                viewModel.meal.isCompleted
                ? "Mark all as not eaten"
                : "Mark all as eaten"
            }
            var image: String {
                viewModel.meal.isCompleted
                ? "circle.dotted"
                : "checkmark.circle"
            }
            
            return Button {
                viewModel.actionHandler(.toggleMealCompletion(viewModel.meal))
            } label: {
                Label(title, systemImage: image)
            }
        }
        var summaryButton: some View {
            Button {
                
            } label: {
                Label("Summary", systemImage: "chart.bar.xaxis")
            }
        }
        
        var foodLabelButton: some View {
            Button {
                
            } label: {
                Label("Food Label", systemImage: "chart.bar.doc.horizontal")
            }
        }
        
        var editMealButton: some View {
            Button {
                tappedEditMeal()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
        
        var deleteMealButton: some View {
            Button(role: .destructive) {
                do {
                    Haptics.warningFeedback()
                    try DataManager.shared.deleteMeal(viewModel.meal)
                } catch {
                    cprint("Couldn't delete meal: \(error)")
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        
        var label: some View {
            Image(systemName: "ellipsis")
                .foregroundColor(.accentColor)
                .padding(.top, 10)
                .padding(.bottom, 5)
                .padding(.leading)
                .padding(.vertical, 12)
                .padding(.trailing, 20)
                .frame(maxHeight: .infinity)
        }
        
        return Menu {
            addFoodButton
            mealCompletionButton
            Divider()
            summaryButton
            foodLabelButton
            Divider()
            editMealButton
            deleteMealButton
        } label: {
            label
        }
        .contentShape(Rectangle())
    }
    
    func tappedEditMeal() {
        viewModel.actionHandler(.editMeal(viewModel.meal))
        //        viewModel.didTapEditMeal(viewModel.meal)
    }
    
    func tappedAddFood() {
//        Haptics.feedback(style: .light)
        //TODO: Present Meal
        viewModel.actionHandler(.addFood(viewModel.meal))
    }
    
    func tappedDeleteMeal() {
        Haptics.feedback(style: .rigid)
        viewModel.tappedDelete()
    }

}
