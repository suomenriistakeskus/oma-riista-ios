import Foundation
import RiistaCommon

protocol UsesControllerWithLoadableModel: ProvidesControllerWithLoadableModel {
    /**
     * A dispose bag for holding Observable subscriptions.
     */
    var disposeBag: DisposeBag { get }
    
    /**
     * A flag for instructing the viewmodel to be refreshed next time there is a possibility
     * (e.g. viewController viewWillAppear is called).
     *
     * Allows e.g. refetching data from the backend after other views possibly have made changes to the content.
     * The flag is should be cleared when viewmodel is being loaded.
     */
    var shouldRefreshViewModel: Bool { get set }

    /**
     * Starts listening the controller viewModelLoadStatus changes.
     */
    func bindToViewModelLoadStatus()

    /**
     * Starts loading the viewmodel if not already loaded.
     */
    func loadViewModelIfNotLoaded(refresh: Bool)
    
    /**
     * Loads the viewmodel.
     *
     * Optionally refreshes the viewModel data (e.g. from network)
     */
    func loadViewModel(refresh: Bool)
}
