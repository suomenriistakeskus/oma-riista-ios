import Foundation

@IBDesignable class SeasonStatsView: UIView {

    let nibName = "SeasonStatsView"

    @IBOutlet weak var contentView: UIView!

    @IBOutlet weak var category1name: UILabel!
    @IBOutlet weak var category2name: UILabel!
    @IBOutlet weak var category3name: UILabel!

    @IBOutlet weak var category1value: UILabel!
    @IBOutlet weak var category2value: UILabel!
    @IBOutlet weak var category3value: UILabel!

    @IBOutlet var topContentPadding: NSLayoutConstraint!
    @IBOutlet var bottomContentPadding: NSLayoutConstraint!
    @IBOutlet var lineSpacingAbove: NSLayoutConstraint!
    @IBOutlet var lineHeight: NSLayoutConstraint!
    @IBOutlet var lineSpacingBelow: NSLayoutConstraint!

    // we don't care about width at this point so not overriding intrinsicContentSize
    var intrinsicContentHeight: CGFloat {
        // assume all values have same height
        let valueHeight = category1value.intrinsicContentSize.height

        // labels may have different heights depending on content
        let maxLabelHeight = max(category1name.intrinsicContentSize.height,
                                 category2name.intrinsicContentSize.height,
                                 category3name.intrinsicContentSize.height)

        let topPadding = topContentPadding.constant
        let bottomPadding = bottomContentPadding.constant
        let spacingAbove = lineSpacingAbove.constant
        let spacingBelow = lineSpacingBelow.constant

        return topPadding
            + valueHeight
            + spacingAbove
            + lineHeight.constant
            + spacingBelow
            + maxLabelHeight
            + bottomPadding
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        xibSetup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }

    func xibSetup() {
        contentView = loadViewFromNib()
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        applyTheme()
    }

    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }

    func applyTheme() {
        self.category1name.configure(for: .label, textAlignment: .center, numberOfLines: 2)
        self.category2name.configure(for: .label, textAlignment: .center, numberOfLines: 2)
        self.category3name.configure(for: .label, textAlignment: .center, numberOfLines: 2)

        self.category1value.configure(fontSize: .huge, textAlignment: .center)
        self.category1value.configure(fontSize: .huge, textAlignment: .center)
        self.category1value.configure(fontSize: .huge, textAlignment: .center)
    }

    func refreshStats(stats: SeasonStats) {
        if let categoryStats = stats.getCategoryStats(categoryId: 1) {
            category1name.text = categoryStats.categoryName
            category1value.text = "\(categoryStats.amount)"
        }

        if let categoryStats = stats.getCategoryStats(categoryId: 2) {
            category2name.text = categoryStats.categoryName
            category2value.text = "\(categoryStats.amount)"
        }

        if let categoryStats = stats.getCategoryStats(categoryId: 3) {
            category3name.text = categoryStats.categoryName
            category3value.text = "\(categoryStats.amount)"
        }
    }
}
