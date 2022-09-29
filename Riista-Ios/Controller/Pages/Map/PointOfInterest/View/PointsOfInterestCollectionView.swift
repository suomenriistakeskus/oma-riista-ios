import Foundation
import UIKit
import RiistaCommon
import Async


fileprivate let SPACING_BETWEEN_PAGES: CGFloat = 12

protocol PointsOfInterestCollectionViewListener: AnyObject {
    func onSelectedPointOfInterestChanged(selectedPoiIndex: Int)
}

class PointsOfInterestCollectionView: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    weak var listener: PointsOfInterestCollectionViewListener?
    weak var navigationControllerProvider: ProvidesNavigationController?

    private(set) var pointsOfInterestViewModel: PoiLocationsViewModel? = nil
    private var pointsOfInterest: [PoiLocationViewModel] {
        pointsOfInterestViewModel?.poiLocations ?? []
    }

    private(set) var selectedIndex: Int = -1

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = SPACING_BETWEEN_PAGES
        // collection view will be constrained so that it extends the screen because otherwise
        // layout.minimumLineSpacing accumulates and pages are no longer centered
        // -> apply a sectionInset in order to correctly center items
        layout.sectionInset = UIEdgeInsets(top: 0, left: SPACING_BETWEEN_PAGES / 2,
                                           bottom: 0, right: SPACING_BETWEEN_PAGES / 2)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true

        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.backgroundColor = UIColor.applicationColor(ViewBackground)
        return collectionView
    }()


    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func updatePointsOfInterest(poiLocationsViewModel: PoiLocationsViewModel) {
        let animate = !self.pointsOfInterest.isEmpty
        let itemsChanged = (self.pointsOfInterestViewModel?.hasSamePoiLocations(other: poiLocationsViewModel) ?? false) == false
        self.pointsOfInterestViewModel = poiLocationsViewModel

        if (itemsChanged) {
            collectionView.reloadData()
        }

        if (self.selectedIndex != poiLocationsViewModel.selectedIndex) {
            // displaying immediately after reloading data doesn't seem work so schedule display
            // to the next runloop cycle
            Async.main {
                self.displayPointOfInterest(index: Int(poiLocationsViewModel.selectedIndex), animated: animate)
            }
        }
    }

    func displayPointOfInterest(index: Int, animated: Bool) {
        self.selectedIndex = index

        collectionView.scrollToItem(at: IndexPath(item: index, section: 0),
                                    at: .centeredHorizontally,
                                    animated: animated)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(round(self.collectionView.contentOffset.x / self.collectionView.bounds.width))
        if (self.selectedIndex != index) {
            self.selectedIndex = index
            listener?.onSelectedPointOfInterestChanged(selectedPoiIndex: index)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pointsOfInterest.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.bounds.size // fullscreen cells
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PointOfInterestCell.REUSE_IDENTIFIER,
            for: indexPath
        ) as! PointOfInterestCell

        cell.navigationControllerProvider = self.navigationControllerProvider
        cell.bind(pointOfInterest: pointsOfInterest[indexPath.row])

        return cell
    }

    private func setupView() {
        backgroundColor = .white
        collectionView.register(PointOfInterestCell.self, forCellWithReuseIdentifier: PointOfInterestCell.REUSE_IDENTIFIER)

        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()

            // constraint beyound superview edges in order to cancel out spacing between pages
            // - otherwise spacing gets accumulated and latter pages are incorrectly positioned
            make.leading.trailing.equalToSuperview().inset(-SPACING_BETWEEN_PAGES / 2)
         }
    }
}
