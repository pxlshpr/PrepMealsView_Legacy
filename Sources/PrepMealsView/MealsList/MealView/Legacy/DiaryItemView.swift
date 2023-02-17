//import SwiftUI
//import SwiftHaptics
//import SwiftUISugar
//import PrepDataTypes
//
////TODO: Possibly remove this
//struct DiaryItemView: View {
//    
//    @Environment(\.colorScheme) var colorScheme
//
//    //TODO: CoreData
////    @ObservedObject var item: FoodItem
//    var item: MealFoodItem
//
////    @Namespace var localNamespace
////    var namespace: Binding<Namespace.ID?>
////    @Binding var namespacePrefix: UUID
//    
//    var body: some View {
//        HStack {
//            optionalEmojiText
//            nameTexts
//            Spacer()
//            isEatenToggle
//        }
//        .listRowBackground(listRowBackground)
//    }
//    
//    var listRowBackgroundColor: Color {
//        if item.isCompleted {
//            return colorScheme == .light ? Color(hex: "EBE9F7") : Color(hex: "191331")
//        } else {
//            return colorScheme == .light ? Color(.secondarySystemGroupedBackground) : Color(hex: "232323")
//        }
//    }
//    var listRowBackground: some View {
//        Color.white
//            .colorMultiply(listRowBackgroundColor)
//            .animation(.default, value: item.isCompleted)
//    }
//    
//    
//    var isEatenToggle: some View {
//        Button {
//            withAnimation {
//                //TODO: Bring this back
////                Store.shared.toggleCompletionForFoodItem(item)
//            }
//            Haptics.feedback(style: .soft)
//        } label: {
//            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle.dotted")
//        }
//        .foregroundColor(item.isCompleted ? .accentColor : Color(.tertiaryLabel))
//        .buttonStyle(.borderless)
//    }
//    
//    @ViewBuilder
//    var optionalEmojiText: some View {
//        Text(item.food.emoji)
//            .font(.body)
////            .if(namespace.wrappedValue != nil) { view in
////                view.matchedGeometryEffect(id: "\(item.id.uuidString)-\(namespacePrefix.uuidString)", in: namespace.wrappedValue!)
////            }
////            .if(namespace.wrappedValue == nil) { view in
////                view.matchedGeometryEffect(id: "\(item.id.uuidString)-\(namespacePrefix.uuidString)", in: localNamespace)
////            }
//    }
//    
//    var nameColor: Color {
//        return Color(.label)
//        //TODO: Bring this back
////        guard let meal = item.meal else {
////            return Color(.secondaryLabel)
////        }
////        return meal.isNextPlannedMeal ? Color(.label) : Color(.secondaryLabel)
//    }
//    
//    var amountColor: Color {
//        return Color(.secondaryLabel)
//        //TODO: Bring this back
////        guard let meal = item.meal else {
////            return Color(.quaternaryLabel)
////        }
////        return meal.isNextPlannedMeal ? Color(.secondaryLabel) : Color(.quaternaryLabel)
//    }
//    
//    var nameTexts: some View {
//        var view = Text(item.food.name)
//            .font(.body)
//            .fontWeight(.semibold)
//            .foregroundColor(nameColor)
//        if let detail = item.food.detail, !detail.isEmpty {
//            view = view
//            + Text(", ")
//                .font(.callout)
//                .foregroundColor(Color(.secondaryLabel))
//            + Text(detail)
//                .font(.callout)
//                .foregroundColor(Color(.secondaryLabel))
//        }
//        if let brand = item.food.brand, !brand.isEmpty {
//            view = view
//            + Text(", ")
//                .font(.callout)
//                .foregroundColor(Color(.tertiaryLabel))
//            + Text(brand)
//                .font(.callout)
//                .foregroundColor(Color(.tertiaryLabel))
//        }
//        view = view
//        + Text(" • ").foregroundColor(Color(.secondaryLabel))
//        + Text(item.quantityDescription)
//
//        .font(.callout)
//        .fontWeight(.semibold)
//        .foregroundColor(amountColor)
//        
//        return view
//    }
//}
//
//
