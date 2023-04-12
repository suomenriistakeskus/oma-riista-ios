import Foundation

import MaterialComponents

class GalleryViewController: UIViewController, UICollectionViewDelegateFlowLayout,
                             RiistaPageDelegate, LogFilterViewDelegate,
                             EntityDataSourceListener {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var filterView: LogFilterView!

    private lazy var galleryDataSource: GalleryDataSource = {
        let dataSource = GalleryDataSource(parentViewController: self)
        dataSource.collectionView = collectionView
        dataSource.listener = self

        return dataSource
    }()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self

        filterView.dataSource = galleryDataSource
        filterView.delegate = self
        filterView.changeListener = SharedEntityFilterStateUpdater()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshAfterManagedObjectContextChange),
                                               name: NSNotification.Name.ManagedObjectContextChanged,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // force reloading gallery data since visible data may have been modified
        // - it is possible to e.g. navigate to ViewObservationViewController and edit image there
        //   -> we want to update observation image once we get back here
        galleryDataSource.shouldReloadData = true
        SharedEntityFilterState.shared.addListener(galleryDataSource)
        filterView.updateTexts()

        self.pageSelected()

        self.title = "Gallery".localized()
    }

    override func viewWillDisappear(_ animated: Bool) {
        SharedEntityFilterState.shared.removeListener(galleryDataSource)

        super.viewWillDisappear(animated)
    }


    // MARK: - Notification handlers

    @objc func refreshAfterManagedObjectContextChange() {
        galleryDataSource.reloadContent()
    }


    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let horizontalSpacing: CGFloat
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            horizontalSpacing = flowLayout.minimumInteritemSpacing + flowLayout.sectionInset.left + flowLayout.sectionInset.right
        } else {
            horizontalSpacing = 30 // some sane default obtained using debugger
        }

        let width: CGFloat = (self.collectionView.frame.size.width - horizontalSpacing) / 2.0
        return CGSize(width: width, height: width + 49)
    }


    // MARK: - RiistaPageDelegate

    func pageSelected() {
    }

    // MARK: - LogFilterViewDelegate

    func onFilterPointOfInterestListClicked() {
        // nop
    }

    func presentSpeciesSelect() {
        guard let navigationController = navigationController else { return }
        filterView.presentSpeciesSelect(navigationController: navigationController)
    }


    // MARK: EntityDataSourceListener

    func onDataSourceDataUpdated(for entityType: FilterableEntityType) {
        filterView.refresh()
    }
}
