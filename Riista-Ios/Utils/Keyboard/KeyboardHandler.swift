import Foundation
import SnapKit

protocol KeyboardHandlerDelegate: AnyObject {
    /**
     * Gets the bottommost view that should remain visible when keyboard is shown. This allows
     * adjusting content so that it moves upwards just the right amount.
     *
     * Return nil if content should be moved upwards by the height of the keyboard.
     */
    func getBottommostVisibleViewWhileKeyboardVisible() -> UIView?
}

/**
 * A swift version of RiistaKeyboardHandler that supports Snapkit constraints. It should be quite easy
 * to support NSLayoutConstraints as well.
 *
 * Also provides a possibility to hide a keyboard and get notified when keyboard has been hidden.
 */
class KeyboardHandler: NSObject, UIGestureRecognizerDelegate {
    /**
     * The delegate for the keyboard handler.
     */
    weak var delegate: KeyboardHandlerDelegate? = nil

    weak var view: UIView?

    /**
     * A gesture recognizer for detecting taps outside of keyboard. Taps to UIControls are not detected.
     */
    private var tapDetector: UITapGestureRecognizer

    /**
     * How the content should be moved?
     */
    enum ContentMovement {
        // Content moved using a constraint defined by SnapKit
        case usingSnapKitConstraint(constraint: Constraint)

        // adjust content inset for the given scrollview
        case adjustContentInset(scrollView: UIScrollView)

        // content should not be moved
        case none
    }

    /**
     * The actual content mover that is able to push content upwards.
     *
     * If null, content won't be moved
     */
    private let contentMover: ContentMover?

    /**
     * A one-time listener for keyboard hiding
     */
    private(set) var onKeyboardHidden: OnCompleted?

    /**
     * Is the keyboard currently visible?
     */
    private(set) var keyboardVisible: Bool = false

    init(view: UIView, contentMovement: ContentMovement) {
        self.view = view
        self.contentMover = contentMovement.createContentMover(view: view)
        tapDetector = UITapGestureRecognizer()

        super.init()

        tapDetector.addTarget(self, action: #selector(tapDetected))
        tapDetector.cancelsTouchesInView = false
        tapDetector.delegate = self
        view.addGestureRecognizer(tapDetector)
    }

    func listenKeyboardEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardWillShow(_:)),
                                               name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardWillHide(_:)),
                                               name: UIWindow.keyboardWillHideNotification, object: nil)
    }

    func stopListenKeyboardEvents() {
        NotificationCenter.default.removeObserver(self)
    }

    func hideKeyboard(_ completion: OnCompleted? = nil) {
        if (!keyboardVisible) {
            onKeyboardHidden = nil
            completion?()
        } else {
            onKeyboardHidden = completion
        }

        view?.endEditing(false)
    }

    @objc func tapDetected() {
        hideKeyboard()
    }


    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view is UIControl) {
            // allow touches to go through to controls (buttons, etc)
            return false
        }

        return true
    }

    @objc func onKeyboardWillShow(_ notification: Notification) {
        if (keyboardVisible) {
            print("Keyboard already visible, not adjusting views!")
            return
        }

        keyboardVisible = true

        guard let userInfo = notification.userInfo, let contentMover = self.contentMover else {
            return
        }

        let animationDuration = userInfo[UIWindow.keyboardAnimationDurationUserInfoKey] as? Double
            ?? AppConstants.Animations.durationDefault

        if let keyboardRect = userInfo[UIWindow.keyboardFrameEndUserInfoKey] as? NSValue {
            let contentPushUpAmount = getContentPushUpAmount(keyboardRect: keyboardRect.cgRectValue)

            contentMover.pushContentUp(relativeAmount: contentPushUpAmount, animationDuration: animationDuration)
        }
    }

    @objc func onKeyboardWillHide(_ notification: Notification) {
        keyboardVisible = false

        guard let userInfo = notification.userInfo, let contentMover = self.contentMover else {
            return
        }

        let animationDuration = userInfo[UIWindow.keyboardAnimationDurationUserInfoKey] as? Double
            ?? AppConstants.Animations.durationDefault

        contentMover.reset(animationDuration: animationDuration) { [weak self] in
            guard let self = self else { return }

            self.onKeyboardHidden?()
            self.onKeyboardHidden = nil
        }
    }

    /**
     * Determines how much the content should be pushed upwards
     */
    private func getContentPushUpAmount(keyboardRect: CGRect) -> CGFloat {
        if let bottommostVisibleView = delegate?.getBottommostVisibleViewWhileKeyboardVisible(),
           let frameMaxY = bottommostVisibleView.frameGlobal?.maxY {

            let spacingBetweenViewAndKeyboard: CGFloat = 8
            let pushAmount = frameMaxY - keyboardRect.minY + spacingBetweenViewAndKeyboard

            // no need to adjust if keyboard won't cover the view
            return max(pushAmount, 0)
        }

        return keyboardRect.height // default value
    }
}

fileprivate protocol ContentMover: AnyObject {
    /**
     * Pushes the content upwards by the given relative amount.
     */
    func pushContentUp(relativeAmount: CGFloat, animationDuration: Double)

    /**
     * Reset back to original content location
     */
    func reset(animationDuration: Double, completion: OnCompleted?)
}

fileprivate class SnapkitConstraintContentMover: ContentMover {
    private let constraint: Constraint
    private weak var view: UIView?

    init(constraint: Constraint, view: UIView) {
        self.constraint = constraint
        self.view = view
    }

    func pushContentUp(relativeAmount: CGFloat, animationDuration: Double) {
        // determine absolute value
        let currentConstant = constraint.layoutConstraints.first?.constant ?? 0

        // pushing upwards by the amount --> subtract
        let newConstant = currentConstant - relativeAmount

        animateBottomConstraintTo(constant: newConstant, animationDuration: animationDuration, completion: nil)
    }

    func reset(animationDuration: Double, completion: OnCompleted?) {
        animateBottomConstraintTo(constant: 0, animationDuration: animationDuration, completion: completion)
    }


    private func animateBottomConstraintTo(constant: CGFloat, animationDuration: Double, completion: OnCompleted?) {
        UIView.animate(withDuration: animationDuration) { [weak self] in
            guard let self = self else { return }

            self.constraint.update(offset: constant)
            self.view?.layoutIfNeeded()
        } completion: { _ in
            completion?()
        }
    }
}

fileprivate class ContentInsetContentMover: ContentMover {
    private weak var scrollView: UIScrollView?
    let initialBottomInset: CGFloat

    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        initialBottomInset = scrollView.contentInset.bottom
    }

    func pushContentUp(relativeAmount: CGFloat, animationDuration: Double) {
        // no need for animations
        let currentBottomInset = scrollView?.contentInset.bottom ?? 0
        setContentInset(bottomInset: currentBottomInset + relativeAmount)
    }

    func reset(animationDuration: Double, completion: OnCompleted?) {
        // no need for animations
        setContentInset(bottomInset: initialBottomInset)
    }


    private func setContentInset(bottomInset: CGFloat) {
        guard let scrollView = scrollView else { return }

        var contentInset = scrollView.contentInset
        contentInset.bottom = bottomInset
        scrollView.contentInset = contentInset
        scrollView.layoutIfNeeded()
    }
}

fileprivate extension KeyboardHandler.ContentMovement {
    func createContentMover(view: UIView) -> ContentMover? {
        switch self {
        case .usingSnapKitConstraint(let constraint):
            return SnapkitConstraintContentMover(constraint: constraint, view: view)
        case .adjustContentInset(let scrollView):
            return ContentInsetContentMover(scrollView: scrollView)
        case .none:
            return nil
        }
    }
}
