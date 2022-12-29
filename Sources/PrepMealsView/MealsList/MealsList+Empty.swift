import SwiftUI

extension MealsList {

    var emptyContent: some View {
        var emptyMessageLayer: some View {
            
            func yOffset(forHeight contentHeight: CGFloat, safeAreaInsets: EdgeInsets) -> CGFloat {
                /// [ ] Handle these hardcoded values gracefully
//                let weekPagerHeight: CGFloat = 45
//                let dayPagerHeight: CGFloat = 27
//                let topHeight: CGFloat = weekPagerHeight + dayPagerHeight + safeAreaInsets.top
                let topHeight: CGFloat = 185

                let bottomHeight: CGFloat = 95

                return (UIScreen.main.bounds.height - topHeight - bottomHeight) / 2.0 - (contentHeight / 2.0)
            }
            
            var emptyMessage: some View {
                GeometryReader { proxy in
                    HStack {
                        Spacer()
                        VStack {
                            Text(emptyText)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color(.tertiaryLabel))
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal)
                            addMealEmptyButton
                        }
                        .frame(width: 300, height: 170)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .foregroundColor(Color(.quaternarySystemFill))
                        )
                        .padding(.horizontal, 50)
                        Spacer()
                    }
                    .offset(y: yOffset(forHeight: 170, safeAreaInsets: proxy.safeAreaInsets))
                }
            }
            
//            return ScrollView {
//                emptyMessage
//            }
//            .fixedSize()

            return ScrollView {
                VStack {
                    Spacer()
                    emptyMessage
                    Spacer()
                }
            }
        }
        
        return ZStack {
            background
            emptyMessageLayer
        }
    }
    
    var addMealEmptyButton: some View {
        let string = isBeforeToday ? "Log a Meal" : "Prep a Meal"
        
        var label: some View {
            HStack {
                Image(systemName: "note.text.badge.plus")
                Text(string)
            }
//            .foregroundColor(.white)
//            .foregroundColor(.secondary)
            .foregroundColor(colorScheme == .light ? Color(.secondarySystemGroupedBackground) : .accentColor)
            .fontWeight(.bold)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
//                    .foregroundStyle(colorScheme == .light ? .regularMaterial : .ultraThinMaterial)
                    .foregroundColor(colorScheme == .light ? Color.accentColor : Color(hex: "343435"))
            )
        }
        
        var button: some View {
            Button {
                actionHandler(.addMeal(nil))
            } label: {
                label
            }
            .buttonStyle(.borderless)
        }
        
        var customButton: some View {
            label
                .onTapGesture {
                    actionHandler(.addMeal(nil))
                }
        }
        
        return button
    }
}

struct MealsListEmptyPreview: View {
    var body: some View {
        MealsList(date: Date(),
                  meals: .constant([]),
                  actionHandler: { _ in }
//                  didTapAddFood: { _ in },
//                  didTapEditMeal: { _ in },
//                  didTapMealFoodItem: { _, _ in },
//                  onTapAddMeal: { _ in }
        )
    }
}

struct MealsListEmpty_Previews: PreviewProvider {
    static var previews: some View {
        MealsListEmptyPreview()
    }
}
