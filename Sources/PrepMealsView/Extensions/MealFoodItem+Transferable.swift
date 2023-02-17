import SwiftUI
import UniformTypeIdentifiers
import PrepDataTypes

extension MealFoodItem: Transferable {
    
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: MealFoodItem.self, contentType: .mealFoodItem)
        //        CodableRepresentation(contentType: .mealFoodItem)
        //        ProxyRepresentation(exporting: \.id.uuidString)
    }
}

extension UTType {
    static var mealFoodItem: UTType { .init(exportedAs: "com.pxlshpr.Prep.mealFoodItem") }
}
