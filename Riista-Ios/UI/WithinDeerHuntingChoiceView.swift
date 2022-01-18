import Foundation

typealias WithinDeerHuntingChoiceViewDelegate = ObservationCategoryChangedDelegate & ProvidesNavigationController

@objc class WithinDeerHuntingChoiceView: UIView, YesNoChoiceViewDelegate {
    weak var delegate: WithinDeerHuntingChoiceViewDelegate?
    private var yesNoView: YesNoChoiceView

    var navigationController: UINavigationController? {
        get {
            return delegate?.navigationController
        }
    }

    @objc init(frame: CGRect, observationCategory: ObservationCategory, delegate: WithinDeerHuntingChoiceViewDelegate?) {
        self.delegate = delegate
        self.yesNoView = YesNoChoiceView(
            frame: frame,
            title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ObservationDetailsWithinDeerHunting"),
            validValueRequired: true,
            value: observationCategory.isWithinDeerHunting()
        )

        super.init(frame: frame)

        self.yesNoView.delegate = self
        addSubview(self.yesNoView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func onYesNoValueChanged(sender: YesNoChoiceView, newValue: Bool?) {
        let newObservationCategory = ObservationCategory.parse(withinDeerHunting: newValue)
        delegate?.onObservationCategoryChanged(newObservationCategory)
    }
}

fileprivate extension ObservationCategory {
    func isWithinDeerHunting() -> Bool? {
        switch self {
        case .mooseHunting, .unknown:
            if (self == .mooseHunting) {
                print("Invalid observationCategory \(self). Bug?")
            }
            return nil
        case .deerHunting:
            return true
        case .normal:
            return false
        }
    }

    static func parse(withinDeerHunting: Bool?) -> ObservationCategory {
        switch withinDeerHunting {
        case .none:
            return .unknown
        case .some(let withinDeerHunting):
            return withinDeerHunting ? .deerHunting : .normal
        }
    }
}

