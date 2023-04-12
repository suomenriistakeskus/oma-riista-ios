import Foundation

@objcMembers class SeasonStats: NSObject {

    var startYear: Int = 0
    var totalAmount: Int = 0
    var monthAmounts: [Int] = Array(repeating: 0, count: 12)

    // Assume category ids are a series starting from 1. Actual values in 2019 are 1/2/3.
    var catNames: NSMutableArray = NSMutableArray()
    var catValues: NSMutableArray = NSMutableArray()

    private(set) var categoryStats: [CategoryStats] = []

    func getCategoryStats(categoryId: Int?) -> CategoryStats? {
        categoryStats.first { $0.categoryId == categoryId }
    }

    func increaseCategoryAmount(categoryId: Int?, by amount: Int?) {
        guard let statsForCategory = getCategoryStats(categoryId: categoryId) else {
            return
        }

        statsForCategory.increaseAmount(by: amount)
    }

    static func empty() -> SeasonStats {
        let season = SeasonStats()

        if let categories = RiistaGameDatabase.sharedInstance()?.categories as? [Int : RiistaSpeciesCategory] {
            let categoryStats: [CategoryStats] = categories.compactMap { _, category in
                CategoryStats(category: category)
            }

            season.categoryStats = categoryStats.sorted { first, second in
                first.categoryId < second.categoryId
            }
        } else {
            print("Failed to obtain categorys, season stats won't be correct!")
        }

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

class CategoryStats {
    let category: RiistaSpeciesCategory

    var categoryId: Int {
        category.categoryId
    }

    var categoryName: String {
        RiistaUtils.name(withPreferredLanguage: category.name)
    }

    private(set) var amount: Int

    fileprivate init(category: RiistaSpeciesCategory) {
        self.category = category
        self.amount = 0
    }

    func increaseAmount(by amount: Int?) {
        guard let amount = amount else {
            return
        }

        self.amount += amount
    }

}
