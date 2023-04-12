import Foundation
import RiistaCommon

/**
 * A helper for UIViewControllers that wish to use ControllerWithLoadableModel but cannot extend BaseControllerWithViewModel.
 *
 * Differs slightly from ControllerHolder in a way that this one allows registering callbacks which are called when needed. ControllerHolder
 * requires an external listener that conforms to ListensViewModelStatusChanges protocol.
 */
class ControllerHolderWithCallbacks<
        ViewModelType,
        Controller: ControllerWithLoadableModel<ViewModelType>
>: UsesControllerWithLoadableModel, ListensViewModelStatusChanges {
    typealias ViewModelType = ViewModelType


    // MARK: Callbacks

    var onWillLoadViewModelCallback: ((_ willRefresh: Bool) -> Void)? = nil
    var onLoadViewModelCompletedCallback: (() -> Void)? = nil
    var onViewModelNotLoadedCallback: (() -> Void)? = nil
    var onViewModelLoadingCallback: (() -> Void)? = nil
    var onViewModelLoadedCallback: ((_ viewModel: ViewModelType) -> Void)? = nil
    var onViewModelLoadFailedCallback: (() -> Void)? = nil



    // MARK: Other properties

    var controller: Controller

    lazy var controllerHolder: ControllerHolder<ViewModelType, Controller, ControllerHolderWithCallbacks<ViewModelType, Controller>> = {
        ControllerHolder(controller: controller, listener: self)
    }()

    var disposeBag: DisposeBag {
        get {
            controllerHolder.disposeBag
        }
        set(value) {
            controllerHolder.disposeBag = value
        }
    }

    var shouldRefreshViewModel: Bool {
        get {
            controllerHolder.shouldRefreshViewModel
        }
        set(value) {
            controllerHolder.shouldRefreshViewModel = value
        }
    }


    // MARK: Initialization

    init(controller: Controller) {
        self.controller = controller
    }

    func onViewWillAppear() {
        controllerHolder.onViewWillAppear()
    }

    func onViewWillDisappear() {
        controllerHolder.onViewWillDisappear()
    }


    // MARK: UsesControllerWithLoadableModel

    func bindToViewModelLoadStatus() {
        controllerHolder.bindToViewModelLoadStatus()
    }

    func loadViewModelIfNotLoaded(refresh: Bool) {
        controllerHolder.loadViewModelIfNotLoaded(refresh: refresh)
    }

    func loadViewModel(refresh: Bool) {
        controllerHolder.loadViewModel(refresh: refresh)
    }


    // MARK: ListensViewModelStatusChanges

    func onWillLoadViewModel(willRefresh: Bool) {
        onWillLoadViewModelCallback?(willRefresh)
    }

    func onLoadViewModelCompleted() {
        onLoadViewModelCompletedCallback?()
    }

    func onViewModelNotLoaded() {
        onViewModelNotLoadedCallback?()
    }

    func onViewModelLoading() {
        onViewModelLoadingCallback?()
    }

    func onViewModelLoaded(viewModel: ViewModelType) {
        onViewModelLoadedCallback?(viewModel)
    }

    func onViewModelLoadFailed() {
        onViewModelLoadFailedCallback?()
    }
}
