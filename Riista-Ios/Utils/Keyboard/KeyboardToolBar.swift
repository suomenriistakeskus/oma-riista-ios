import Foundation

@objc class KeyboardToolBarHelper: NSObject {
    /**
     * A static helper for adding 'done' button on top of keyboard. The resulting view should be
     * added as `inputAccessoryView`.
     */
    @objc static func hideKeyboardWhenDone(_ view: UIView) -> UIView {
        KeyboardToolBar().hideKeyboardOnDone(editView: view)
    }
}

class KeyboardToolBar: UIToolbar {
    private static var logger = AppLogger(for: KeyboardToolBar.self, printTimeStamps: false)

    private(set) lazy var doneButton: MaterialButton = {
        let btn = MaterialButton()
        btn.setTitleFont(UIFont.appFont(for: .button), for: .normal)
        btn.setTitle("KeyboardDone".localized(), for: .normal)
        btn.setTitleColor(UIColor.applicationColor(Primary), for: .normal)
        btn.applyTextTheme(withScheme: AppTheme.shared.textButtonScheme())
        btn.onClicked = {
            self.onDoneClicked?()
        }
        return btn
    }()

    var onDoneClicked: OnClicked?

    convenience init() {
        self.init(
            frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        )
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func hideKeyboardOnDone(editView: UIView) -> Self {
        onDoneClicked = { [weak editView] in
            editView?.endEditing(false)
        }

        return self
    }

    @objc private func handleDoneClicked() {
        guard let onDoneClicked = onDoneClicked else {
            Self.logger.w { "No click handler for 'done' specified, nothing to do."}
            return
        }

        onDoneClicked()
    }

    private func setup() {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.setItems([
            flexibleSpace,
            UIBarButtonItem(customView: doneButton)
        ], animated: false)
    }
}
