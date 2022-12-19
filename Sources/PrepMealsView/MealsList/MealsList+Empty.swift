import SwiftUI

extension MealsList {

    var emptyContent: some View {
        var emptyMessageLayer: some View {
            
            func yOffset(forHeight contentHeight: CGFloat, safeAreaInsets: EdgeInsets) -> CGFloat {
                /// [ ] Handle these hardcoded values gracefully
                let weekPagerHeight: CGFloat = 45
                let dayPagerHeight: CGFloat = 27
                let bottomHeight: CGFloat = 95
                
                let topHeight: CGFloat = weekPagerHeight + dayPagerHeight + safeAreaInsets.top
                
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
                            addMealEmptyButton
                        }
                        .frame(width: 100, height: 100)
//                        .padding()
//                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .foregroundColor(Color(.quaternarySystemFill))
                        )
                        .padding(.horizontal, 50)
                        Spacer()
                    }
//                    .offset(y: yOffset(forHeight: proxy.size.height, safeAreaInsets: proxy.safeAreaInsets))
                }
            }
            
            return ScrollView {
                emptyMessage
            }
//            .fixedSize()
            
//            return ScrollView {
//                VStack {
//                    Spacer()
//                    emptyMessage
//                    Spacer()
//                }
//            }
        }
        
        return ZStack {
            background
            emptyMessageLayer
        }
    }
    
    var addMealEmptyButton: some View {
        let string = isBeforeToday ? "Log a Meal" : "Prep a Meal"
        return Button {
            actionHandler(.addMeal(nil))
//            onTapAddMeal(nil)
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
