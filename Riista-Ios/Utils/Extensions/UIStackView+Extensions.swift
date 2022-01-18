import Foundation


extension UIStackView {
    /**
     * Adds the given view optionally including space before or after given view.
     *
     * The space will take the UIStackView.spacing into account i.e. if UIStackView.spacing == 4 and
     * addView(view, spaceBefore: 4) is called, the result will be
     *  <previous view>
     *  <space == 4>
     *  <view>
     */
    func addView(_ view: UIView, spaceBefore: CGFloat? = nil, spaceAfter: CGFloat? = nil) {
        if let spaceBefore = spaceBefore {
            addSpacer(size: spaceBefore)
        }
        addArrangedSubview(view)
        if let spaceAfter = spaceAfter {
            addSpacer(size: spaceAfter)
        }
    }

    func addSeparator(spaceBefore: CGFloat? = nil, spaceAfter: CGFloat? = nil) {
        let separator = SeparatorView(orientation: axis == .vertical ? .horizontal : .vertical)
        addView(separator, spaceBefore: spaceBefore, spaceAfter: spaceAfter)
    }

    func addSeparator(spaceAround: CGFloat? = nil) {
        let space = spaceAround.map { $0 / 2 }
        addSeparator(spaceBefore: space, spaceAfter: space)
    }

    /**
     * Adds a spacer view to the list of arranged subviews.
     *
     * The size will take the UIStackView.spacing into account i.e. if UIStackView.spacing == 4 and
     * addView(view, spaceBefore: 4) is called, the result will be
     *  <previous view>
     *  <space == 4>
     *  <view to be added next>
     */
    func addSpacer(size: CGFloat, canShrink: Bool = false, canExpand: Bool = false) {
        let spacer = UIView()
        spacer.backgroundColor = nil

        let spacingAbove = arrangedSubviews.isEmpty ? 0 : spacing
        // assume there will be a view after this spacer --> subtract spacing at least once
        let spacingBelow = spacing

        let spacerSize = max(0, size - spacingAbove - spacingBelow)

        var relation: Relation = .equalTo
        var priority: Int = 1000
        var compressionResistance: Float = 750
        var huggingPriority: Float = 750
        let priorityLow = 10

        if (canShrink && canExpand) {
            priority = priorityLow
            compressionResistance = 10
            huggingPriority = 10
        } else if (canShrink) {
            relation = .lessThanOrEqualTo
            compressionResistance = 10
        } else if (canExpand) {
            relation = .greaterThanOrEqualTo
            huggingPriority = 10
        }

        if (self.axis == .vertical) {
            spacer.snp.makeConstraints { make in
                make.height.relatedTo(spacerSize, relation: relation).priority(priority)
                if (canShrink || canExpand) {
                    // try to keep desired size
                    make.height.equalTo(spacerSize).priority(priorityLow)
                }
            }
        } else {
            spacer.snp.makeConstraints { make in
                make.width.relatedTo(spacerSize, relation: relation).priority(priority)
                if (canShrink || canExpand) {
                    // try to keep desired size
                    make.width.equalTo(spacerSize).priority(priorityLow)
                }
            }
        }

        spacer.setContentCompressionResistancePriority(UILayoutPriority(compressionResistance), for: axis)
        spacer.setContentHuggingPriority(UILayoutPriority(huggingPriority), for: axis)

        addArrangedSubview(spacer)
    }

    func toggleSubviewVisibility(view: UIView, animate: Bool = true) {
        if (view.isHidden) {
            showSubview(view: view, animate: animate)
        } else {
            hideSubview(view: view, animate: animate)
        }
    }

    func hideSubview(view: UIView, animate: Bool = true) {
        if (!view.isHidden) {
            if (animate) {
                UIView.animate(
                    withDuration: AppConstants.Animations.durationDefault,
                    delay: 0,
                    usingSpringWithDamping: 0.9,
                    initialSpringVelocity: 1,
                    options: [],
                    animations: {
                        view.alpha = 0
                        view.isHidden = true
                        self.layoutIfNeeded()
                    },
                    completion: nil
                )
            } else {
                view.isHidden = true
            }
        }
    }

    func showSubview(view: UIView, animate: Bool = true) {
        if (view.isHidden) {
            if (animate) {
                UIView.animate(
                    withDuration: AppConstants.Animations.durationDefault,
                    delay: 0,
                    usingSpringWithDamping: 0.9,
                    initialSpringVelocity: 1,
                    options: [],
                    animations: {
                        view.isHidden = false
                        view.alpha = 1
                        self.layoutIfNeeded()
                    },
                    completion: nil
                )
            } else {
                view.alpha = 1
                view.isHidden = false
            }
        }
    }
}

