import SwiftUI
import PrepDataTypes

extension Array where Element == MealFoodItem {
    
    var hasValidSortPositions: Bool {
        for i in self.indices {
            guard self[i].sortPosition == i + 1 else {
                return false
            }
        }
        return true
    }
    
    mutating func resetSortPositions(aroundFoodItemWithId id: UUID?, movingForwards: Bool = false) {
        
        /// Don't continue if the sort positions are valid
        guard !hasValidSortPositions else {
            return
        }
        
        if let id {
            /// First get the index and remove the `foodItem`
            guard let currentIndex = self.firstIndex(where: { $0.id == id }) else {
                return
            }
            let removed = self.remove(at: currentIndex)
            
            /// Now insert it where it actually belongs
            var newIndex = removed.sortPosition - (movingForwards ? 2 : 1)
            
            cprint("🔀 newIndex for: \(removed.food.name) is \(newIndex)")
            if newIndex > self.count {
                newIndex = self.count
                cprint("🔀 Changed newIndex to \(newIndex) since it was out of bounds (greater than \(self.count))")
            }
            
            if newIndex <= self.count , newIndex >= 0 {
                cprint("🔀 Inserting \(removed.food.name) at \(newIndex)")
                self.insert(removed, at: newIndex)
            } else {
                cprint("🔀 NOT Inserting \(removed.food.name) at \(newIndex) because it's out of bounds")
            }
        }

        cprint("🔀 Before re-number: \(map({ "\($0.sortPosition)" }).joined(separator: ", "))")

        /// Finally, renumber all the items for the array just to be safe (can be optimised later)
        for i in self.indices {
            self[i].sortPosition = i + 1
        }
        
        cprint("🔀 After re-number: \(map({ "\($0.sortPosition)" }).joined(separator: ", "))")
    }
}
