import Foundation
import UIKit
import RiistaCommon

class PointOfInterestCell: UICollectionViewCell {
    static let REUSE_IDENTIFIER = "PointOfInterestCell"

    private let pointOfInterestView = PointOfInterestView()

    var navigationControllerProvider: ProvidesNavigationController? {
        get {
            pointOfInterestView.navigationControllerProvider
        }
        set(provider) {
            pointOfInterestView.navigationControllerProvider = provider
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func bind(pointOfInterest: PoiLocationViewModel) {
        pointOfInterestView.updateValues(pointOfInterest: pointOfInterest)
    }

    private func setup() {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = UIColor.applicationColor(ViewBackground)
        scrollView.layoutMargins = UIEdgeInsets.zero
        contentView.addSubview(scrollView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(pointOfInterestView)
        pointOfInterestView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(scrollView.layoutMarginsGuide)
            make.top.bottom.equalToSuperview()
        }
    }
}
