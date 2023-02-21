import SwiftUI
import UniformTypeIdentifiers
import PrepDataTypes

extension DayMeal: Transferable {
    
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: DayMeal.self, contentType: .dayMeal)
        //        CodableRepresentation(contentType: .mealFoodItem)
        //        ProxyRepresentation(exporting: \.id.uuidString)
    }
}

extension UTType {
    static var dayMeal: UTType { .init(exportedAs: "com.pxlshpr.Prep.dayMeal") }
}
