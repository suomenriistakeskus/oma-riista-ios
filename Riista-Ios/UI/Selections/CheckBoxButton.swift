import Foundation
import SnapKit

class CheckBoxButton: MaterialButton {

    var onSelectionChanged: OnSelectedDataChanged<Bool>?

    override init() {
        super.init()

        titleLabel?.numberOfLines = 0

        self.setImage(UIImage(named: "tick_box"), for: .selected)
        self.setImage(UIImage(named: "empty_box"), for: .normal)
        self.addTarget(self, action: #selector(CheckBoxButton.buttonClicked(_:)), for: .touchUpInside)
        self.applyTextTheme(withScheme: AppTheme.shared.textButtonScheme())
        self.contentHorizontalAlignment = .left

        self.imageEdgeInsets = UIEdgeInsets(
            top: self.imageEdgeInsets.top,
            left: -12,
            bottom: self.imageEdgeInsets.bottom,
            right: 0
        )
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc func buttonClicked(_ sender: UIButton) {
        if sender == self {
            onSelectionChanged?(!self.isSelected)
        }
     }
}
