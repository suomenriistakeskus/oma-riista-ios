import Foundation

@objcMembers class SeasonStats: NSObject {

    var startYear: Int = 0
    var totalAmount: Int = 0
    var monthAmounts: [Int] = Array(repeating: 0, count: 12)

    // Assume category ids are a series starting from 1. Actual values in 2019 are 1/2/3.
    var catNames: NSMutableArray = NSMutableArray()
    var catValues: NSMutableArray = NSMutableArray()

    static func empty() -> SeasonStats {
        let season = SeasonStats()

        let categories = RiistaGameDatabase.sharedInstance()?.categories

        season.catNames.add(categoryName(item: categories![1]))
        season.catNames.add(categoryName(item: categories![2]))
        season.catNames.add(categoryName(item: categories![3]))

        season.catValues.addObjects(from: [0, 0, 0])

        return season
    }

    static func categoryName(item: Any?) -> String {
        let cat = item as! RiistaSpeciesCategory

        return RiistaUtils.name(withPreferredLanguage: cat.name)
    }

    func mutableMonthArray() -> NSMutableArray {
        return NSMutableArray(array: monthAmounts)
    }
}
