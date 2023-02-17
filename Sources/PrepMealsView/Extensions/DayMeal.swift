import SwiftUI
import PrepDataTypes

extension DayMeal {
    var timeDate: Date {
        Date(timeIntervalSince1970: time)
    }
}


extension DayMeal {
    var energyValuesInKcalDecreasing: [Double] {
        foodItems
            .map { $0.scaledValueForEnergyInKcal }
            .sorted { $0 > $1 }
    }
    var largestEnergyInKcal: Double {
        energyValuesInKcalDecreasing.first ?? 0
    }
    
    var smallestEnergyInKcal: Double {
        energyValuesInKcalDecreasing.last ?? 0
    }
}

