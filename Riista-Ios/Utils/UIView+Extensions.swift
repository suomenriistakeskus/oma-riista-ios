import Foundation
import Async
import SnapKit

extension UIView {
    var parentViewController: UIViewController? {
        // Starts from next (As we know self is not a UIViewController).
        var parentResponder: UIResponder? = self.next
        while parentResponder != nil {
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
            parentResponder = parentResponder?.next
        }
        return nil
    }

    func removeAllConstraints() {
        var _parentView = self.superview

        while let parentView = _parentView {
            for constraint in parentView.constraints {
                if let firstView = constraint.firstItem as? UIView, firstView == self {
                    parentView.removeConstraint(constraint)
                }
                if let secondView = constraint.secondItem as? UIView, secondView == self {
                    parentView.removeConstraint(constraint)
                }
            }

            _parentView = parentView.superview
        }

        removeConstraints(self.constraints)
    }

    @objc func removeAllSubviews() {
        let subviewsToBeRemoved = self.subviews
        for subview in subviewsToBeRemoved {
            subview.removeFromSuperview()
        }
    }

    func updateLayoutMargins(
        top: CGFloat? = nil,
        left: CGFloat? = nil,
        bottom: CGFloat? = nil,
        right: CGFloat? = nil
    ) {
        let old = self.layoutMargins

        layoutMargins = UIEdgeInsets.init(
            top: top ?? old.top,
            left: left ?? old.left,
            bottom: bottom ?? old.bottom,
            right: right ?? old.right
        )
    }

    func updateLayoutMargins(all: CGFloat) {
        layoutMargins = UIEdgeInsets(top: all, left: all, bottom: all, right: all)
    }

    func updateLayoutMargins(horizontal: CGFloat, vertical: CGFloat) {
        layoutMargins = UIEdgeInsets(top: vertical, left: horizontal,
                                     bottom: vertical, right: horizontal)
    }

    func updateFrame(
        x: CGFloat? = nil,
        y: CGFloat? = nil,
        width: CGFloat? = nil,
        height: CGFloat? = nil
    ) {
        let old = self.frame

        frame = CGRect(
            x: x ?? old.minX,
            y: y ?? old.minY,
            width: width ?? old.width,
            height: height ?? old.height
        )
    }

    func isAnimatingView() -> Bool {
        return (self.layer.animationKeys()?.count ?? 0) > 0
    }

    func fadeIn(
        duration: TimeInterval = AppConstants.Animations.durationDefault,
        completion: OnCompleted? = nil
    ) {
        fadeTo(1.0, duration: duration, completion: completion)
    }

    func fadeOut(
        duration: TimeInterval = AppConstants.Animations.durationDefault,
        completion: OnCompleted? = nil
    ) {
        fadeTo(0.0, duration: duration, completion: completion)
    }

    func fadeTo(
        _ targetAlpha: CGFloat,
        duration: TimeInterval = AppConstants.Animations.durationDefault,
        completion: OnCompleted? = nil
    ) {
        Async.main { [weak self] in
            guard let self = self else { return }

            UIView.animate(withDuration: duration) {
                self.alpha = targetAlpha
            } completion: { _ in
                completion?()
            }
        }
    }

    func constrainSizeTo(height: CGFloat? = nil,
                         heightRelation: Relation = .equalTo,
                         width: CGFloat? = nil,
                         widthRelation: Relation = .equalTo,
                         priority: Int = 1000) {
        self.snp.makeConstraints { make in
            if let height = height {
                make.height.relatedTo(height, relation: heightRelation).priority(priority)
            }
            if let width = width {
                make.width.relatedTo(width, relation: widthRelation).priority(priority)
            }
        }
    }

    func withSeparatorAtBottom() -> Self {
        addSeparatorToBottom()
        return self
    }

    func withSeparatorAtTrailing() -> Self {
        addSeparatorToTrailing()
        return self
    }

    func addSeparatorToBottom(respectLayoutMarginsGuide: Bool = false) {
        let separator = SeparatorView(orientation: .horizontal)
        addSubview(separator)
        separator.snp.makeConstraints { make in
            if respectLayoutMarginsGuide, let layoutMarginsGuide = superview?.layoutMarginsGuide {
                make.leading.trailing.equalTo(layoutMarginsGuide)
                make.bottom.equalToSuperview()
            } else {
                make.leading.trailing.bottom.equalToSuperview()
            }
        }
    }

    func addSeparatorToTrailing(respectLayoutMarginsGuide: Bool = false) {
        let separator = SeparatorView(orientation: .vertical)
        addSubview(separator)
        separator.snp.makeConstraints { make in
            if respectLayoutMarginsGuide, let layoutMarginsGuide = superview?.layoutMarginsGuide {
                make.top.bottom.equalTo(layoutMarginsGuide)
                make.trailing.equalToSuperview()
            } else {
                make.top.bottom.trailing.equalToSuperview()
            }
        }
    }

    /**
     * Disclaimer: on iOS10, ensure that bounds are valid as otherwise corners won't be rounded.
     */
    func roundAllCorners(cornerRadius: CGFloat) {
        roundCorners(
            corners: CACornerMask.allCorners(),
            cornerRadius: cornerRadius
        )
    }

    /**
     * Disclaimer: on iOS10, ensure that bounds are valid as otherwise corners won't be rounded.
     */
    func roundCorners(corners: CACornerMask, cornerRadius: CGFloat) {
        clipsToBounds = true
        if #available(iOS 11.0, *) {
            layer.cornerRadius = cornerRadius
            layer.maskedCorners = corners
        } else {
            // check bounds so that we don't accidentally hide the view
            if (bounds.width < 1 || bounds.height < 1) {
                print("NOT ROUNDING CORNERS, no size information available!")
                return
            }
            let maskLayer = CAShapeLayer()
            maskLayer.path = UIBezierPath(
                roundedRect: bounds,
                byRoundingCorners: corners.toUIRectCorner(),
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            ).cgPath
            layer.mask = maskLayer
        }
    }

    /**
     * Frame in global coordinates (i.e. rootViewController's coordinate system)
     */
    var frameGlobal: CGRect? {
        let rootView = UIApplication.shared.keyWindow?.rootViewController?.view
        // bounds conversion is same as if superview converted this view's frame
        return convert(bounds, to: rootView)
    }
}

fileprivate extension CACornerMask {
    func toUIRectCorner() -> UIRectCorner {
        var result: UIRectCorner = []
        if (contains(.layerMinXMinYCorner)) {
            result.insert(.topLeft)
        }
        if (contains(.layerMaxXMinYCorner)) {
            result.insert(.topRight)
        }
        if (contains(.layerMinXMaxYCorner)) {
            result.insert(.bottomLeft)
        }
        if (contains(.layerMaxXMaxYCorner)) {
            result.insert(.bottomRight)
        }

        if (result.contains(.topLeft) && result.contains(.topRight) &&
                result.contains(.bottomLeft) && result.contains(.bottomRight)) {
            return .allCorners
        }

        return result
    }
}

extension CACornerMask {
    static func allCorners() -> CACornerMask {
        return [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    }
}
