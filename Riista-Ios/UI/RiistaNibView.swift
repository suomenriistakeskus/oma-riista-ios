import UIKit

class RiistaNibView: UIView {
    var view: UIView!
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Setup view from .xib file
        xibSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        // Setup view from .xib file
        xibSetup()
    }
}

private extension RiistaNibView {
    func xibSetup() {
        backgroundColor = UIColor.clear
        guard let nibView = loadNib() else {
            print("Failed to load NIB \(type(of: self).description())")
            return
        }
        view = nibView

        // use bounds not frame or it'll be offset
        view.frame = bounds
        // Adding custom subview on top of our view
        addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[childView]|",
                                                      options: [],
                                                      metrics: nil,
                                                      views: ["childView": view!]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[childView]|",
                                                      options: [],
                                                      metrics: nil,
                                                      views: ["childView": view!]))
    }
}

extension UIView {
    /** Loads instance from nib with the same name. */
    func loadNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nibName = type(of: self).description().components(separatedBy: ".").last!
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
}

