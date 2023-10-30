import Foundation

class ClickableCellBackground: ButtonWithRoundedCorners {

    /**
     * What to do when clicked?
     */
    var onClicked: OnClicked?

    /**
     * The background color when highlighted (i.e. pressed)
     */
    var backgroundColorNormal: UIColor = UIColor.applicationColor(ViewBackground)

    /**
     * The background color when highlighted (i.e. pressed)
     */
    var backgroundColorHighlighted: UIColor = UIColor.applicationColor(GreyLight)


    override var isHighlighted: Bool {
        get {
            super.isHighlighted
        }
        set(highlighted) {
            super.isHighlighted = highlighted
            updateBackgroundColor()
        }
    }

    init() {
        super.init(frame: CGRect.zero)
        addTarget(self, action: #selector(handleClicked), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc func handleClicked() {
        onClicked?()
    }

    private func updateBackgroundColor() {
        if (isHighlighted) {
            backgroundColor = backgroundColorHighlighted
        } else {
            backgroundColor = backgroundColorNormal
        }
    }
}
