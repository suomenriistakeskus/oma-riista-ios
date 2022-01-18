import Foundation


protocol ListensViewModelStatusChanges: AnyObject {
    associatedtype ViewModelType: AnyObject


    // MARK: load operation

    /**
     * Indicates that viewmodel loading will be started. This is a good place to indicate loading
     * e.g. if refreshing contents from the web.
     */
    func onWillLoadViewModel(willRefresh: Bool)

    /**
     * Indicates that viewmodel loading has been completed. This is a good place to hide any loading indicators.
     */
    func onLoadViewModelCompleted()


    // MARK: ViewModel load status notifications

    /**
     * Called when viewmodel has not yet been loaded.
     */
    func onViewModelNotLoaded()

    /**
     * Called when viewmodel is being loaded.
     */
    func onViewModelLoading()

    /**
     * Called when viewmodel has been loaded.
     */
    func onViewModelLoaded(viewModel: ViewModelType)

    /**
     * Called when viewmodel loading failed.
     */
    func onViewModelLoadFailed()
}

