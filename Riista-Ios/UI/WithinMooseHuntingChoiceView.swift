import Foundation

typealias WithinMooseHuntingChoiceViewDelegate = ObservationCategoryChangedDelegate & ProvidesNavigationController

@objc class WithinMooseHuntingChoiceView: UIView, YesNoChoiceViewDelegate {
    weak var delegate: WithinMooseHuntingChoiceViewDelegate?
    private var yesNoView: YesNoChoiceView

    var navigationController: UINavigationController? {
        get {
            return delegate?.navigationController
        }
    }

    @objc init(frame: CGRect, observationCategory: ObservationCategory, delegate: WithinMooseHuntingChoiceViewDelegate?) {
        self.delegate = delegate
        self.yesNoView = YesNoChoiceView(
            frame: frame,
            title: RiistaBridgingUtils.RiistaLocalizedString(forkey: "ObservationDetailsWithinMooseHunting"),
            validValueRequired: true,
            value: observationCategory.isWithinMooseHunting()
        )

        super.init(frame: frame)

        self.yesNoView.delegate = self
        addSubview(self.yesNoView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func onYesNoValueChanged(sender: YesNoChoiceView, newValue: Bool?) {
        let newObservationCategory = ObservationCategory.parse(withinMooseHunting: newValue)
        delegate?.onObservationCategoryChanged(newObservationCategory)
    }
}

fileprivate extension ObservationCategory {
    func isWithinMooseHunting() -> Bool? {
        switch self {
        case .deerHunting, .unknown:
            if (self == .deerHunting) {
                print("Invalid observationCategory \(self). Bug?")
            }
            return nil
        case .mooseHunting:
            return true
        case .normal:
            return false
        }
    }

    static func parse(withinMooseHunting: Bool?) -> ObservationCategory {
        switch withinMooseHunting {
        case .none:
            return .unknown
        case .some(let withinMooseHunting):
            return withinMooseHunting ? .mooseHunting : .normal
        }
    }
}

