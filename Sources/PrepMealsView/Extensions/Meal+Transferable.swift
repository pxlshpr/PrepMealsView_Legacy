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


import CoreTransferable

/// From: https://stackoverflow.com/questions/74290721/how-do-you-mark-a-single-container-as-a-dropdestination-for-multiple-transferabl
enum DropItem: Codable, Transferable {
    case none
    case meal(DayMeal)
    case foodItem(MealFoodItem)
    
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { DropItem.meal($0) }
        ProxyRepresentation { DropItem.foodItem($0) }
    }
    
    var meal: DayMeal? {
        switch self {
            case .meal(let meal): return meal
            default: return nil
        }
    }
    
    var foodItem: MealFoodItem? {
        switch self {
            case.foodItem(let foodItem): return foodItem
            default: return nil
        }
    }
    
    var description: String {
        switch self {
        case .none:
            return "None"
        case .meal(let dayMeal):
            return dayMeal.description
        case .foodItem(let foodItem):
            return foodItem.description
        }
    }
}
