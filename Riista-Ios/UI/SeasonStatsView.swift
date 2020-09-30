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

        return topContentPadding.constant
            + valueHeight
            + lineSpacingAbove.constant
            + lineHeight.constant
            + lineSpacingBelow.constant
            + maxLabelHeight
            + bottomContentPadding.constant
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
        AppTheme.shared.setupLabelFont(label: self.category1name)
        AppTheme.shared.setupLargeValueFont(label: self.category1value)
        AppTheme.shared.setupLabelFont(label: self.category2name)
        AppTheme.shared.setupLargeValueFont(label: self.category2value)
        AppTheme.shared.setupLabelFont(label: self.category3name)
        AppTheme.shared.setupLargeValueFont(label: self.category3value)
    }

    func refreshStats(stats: SeasonStats) {
        category1name.text = String(describing: stats.catNames[0])
        category2name.text = String(describing: stats.catNames[1])
        category3name.text = String(describing: stats.catNames[2])

        category1value.text = String(describing: stats.catValues[0])
        category2value.text = String(describing: stats.catValues[1])
        category3value.text = String(describing: stats.catValues[2])
    }
}
