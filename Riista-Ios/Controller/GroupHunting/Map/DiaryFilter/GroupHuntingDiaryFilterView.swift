import Foundation
import MaterialComponents
import RiistaCommon


class GroupHuntingDiaryFilterView: MDCCard {

    lazy var button: MaterialButton = {
        let button = MaterialButton()
        button.applyTextTheme(withScheme: AppTheme.shared.outlineButtonScheme())
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center

        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func update(with diaryFilter: DiaryFilter) {
        let text = diaryFilter.acceptStatus.toAcceptStatus().localized() + " " +
            diaryFilter.eventType.toEventType().localized()

        button.setTitle(text.lowercased().capitalized, for: .normal)
    }

    private func setup() {
        addSubview(button)

        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let myHeight = AppConstants.UI.ButtonHeightSmall
        shapeGenerator = AppTheme.shared.roundedCornersShapeGenerator(radius: myHeight / 2)
        button.shapeGenerator = shapeGenerator

        self.snp.makeConstraints { make in
            make.height.equalTo(myHeight)
        }
    }
}
