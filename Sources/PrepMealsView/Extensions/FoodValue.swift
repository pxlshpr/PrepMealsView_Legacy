import Foundation
import PrepDataTypes

extension FoodValue {
    func description(with food: Food) -> String {
        "\(value.cleanAmount) \(unitDescription(sizes: food.info.sizes))"
    }
}
