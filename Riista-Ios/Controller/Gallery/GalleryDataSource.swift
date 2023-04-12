import Foundation


class GalleryDataSource: UnifiedEntityDataSource {

    private lazy var galleryCollectionViewController: GalleryCollectionViewController = {
        GalleryCollectionViewController(galleryDataSource: self, parentViewController: parentViewController)
    }()

    weak var listener: EntityDataSourceListener?

    private weak var parentViewController: UIViewController?

    var collectionView: UICollectionView? {
        didSet {
            collectionView?.dataSource = galleryCollectionViewController
            shouldReloadData = true
        }
    }

    init(parentViewController: UIViewController) {
        self.parentViewController = parentViewController

        super.init(
            onlyEntitiesWithImages: true,
            supportedDataSourceTypes: [.harvest, .observation, .srva]
        )
    }

    override func reloadContent(_ onCompleted: OnCompleted? = nil) {
        fetchEntitiesAndReloadTableviewData(onCompleted)
    }

    override func onFilterApplied(dataSourceChanged: Bool, filteredDataChanged: Bool) {
        if (!dataSourceChanged && !filteredDataChanged && !shouldReloadData) {
            print("No need to reload gallery data!")
            return
        }

        fetchEntitiesAndReloadTableviewData()
    }

    private func fetchEntitiesAndReloadTableviewData(_ onCompleted: OnCompleted? = nil) {
        guard let dataSource = activeDataSource else {
            print("No data source, cannot fetch entities!")
            return
        }

        shouldReloadData = false

        dataSource.fetchEntities()
    }


    // MARK: EntityDataSourceListener

    override func onDataSourceDataUpdated(for entityType: FilterableEntityType) {
        guard let currentEntityType = activeDataSource?.filteredEntityType, currentEntityType == entityType else {
            return
        }

        self.collectionView?.reloadData()
        self.listener?.onDataSourceDataUpdated(for: entityType)
    }
}

// data source + delegate for the CollectionView in a separate class as it needs to inherit NSObject
fileprivate class GalleryCollectionViewController: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    let galleryDataSource: GalleryDataSource
    private weak var parentViewController: UIViewController?

    private var dataSource: FilterableEntityDataSource? {
        get {
            galleryDataSource.activeDataSource
        }
    }

    init(galleryDataSource: GalleryDataSource, parentViewController: UIViewController?) {
        self.galleryDataSource = galleryDataSource
        self.parentViewController = parentViewController
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.getTotalEntityCount() ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryItemCell", for: indexPath) as! GalleryItemCell

        guard let parentViewController = parentViewController else {
            return cell
        }

        if let filteredEntityType = dataSource?.filteredEntityType {
            switch filteredEntityType {
            case .harvest:
                if let harvest = galleryDataSource.getHarvest(specifiedBy: .index(indexPath.row)) {
                    cell.setupFrom(diaryEntry: harvest, parent: parentViewController)
                }
            case .observation:
                if let observation = galleryDataSource.getObservation(specifiedBy: .index(indexPath.row)) {
                    cell.setupFrom(observation: observation, parent: parentViewController)
                }
            case .srva:
                if let srva = galleryDataSource.getSrva(specifiedBy: .index(indexPath.row)) {
                    cell.setupFrom(srva: srva, parent: parentViewController)
                }
            case .pointOfInterest:
                print("Cannot display points-of-interest in gallery")
                break
            }
        }

        return cell
    }
}
