import Foundation
import RiistaCommon

/**
 * A helper for UIViewControllers that wish to use ControllerWithLoadableModel but cannot extend BaseControllerWithViewModel.
 */
class ControllerHolder<
        ViewModelType,
        Controller: ControllerWithLoadableModel<ViewModelType>,
        ListenerType : ListensViewModelStatusChanges
>: UsesControllerWithLoadableModel, ListensViewModelStatusChanges where ListenerType.ViewModelType == ViewModelType {
    typealias ViewModelType = ViewModelType

    var controller: Controller
    internal var disposeBag = DisposeBag()
    var shouldRefreshViewModel: Bool = false

    weak var listener: ListenerType?

    init(controller: Controller, listener: ListenerType) {
        self.controller = controller
        self.listener = listener
    }

    func onViewWillAppear() {
        bindToViewModelLoadStatus()
        loadViewModelIfNotLoaded(refresh: shouldRefreshViewModel)
    }

    func onViewWillDisappear() {
        disposeBag.disposeAll()
    }

    func bindToViewModelLoadStatus() {
        controller.viewModelLoadStatus.bindAndNotify { [weak self] viewModelLoadStatus in
            guard let self = self else { return }
            guard let viewModelLoadStatus = viewModelLoadStatus else { return }

            if (viewModelLoadStatus == ViewModelLoadStatusNotLoaded.shared) {
                self.onViewModelNotLoaded()
            } else if (viewModelLoadStatus == ViewModelLoadStatusLoading.shared) {
                self.onViewModelLoading()
            } else if (viewModelLoadStatus == ViewModelLoadStatusLoadFailed.shared) {
                self.onViewModelLoadFailed()
            } else if let loadedState = viewModelLoadStatus as? ViewModelLoadStatusLoaded<ViewModelType> {
                self.onViewModelLoaded(viewModel: loadedState.viewModel)
            } else {
                fatalError("Unknown ViewModelLoadStatus!")
            }
        }.disposeBy(disposeBag: disposeBag)
    }

    func loadViewModelIfNotLoaded(refresh: Bool) {
        if (controller.getLoadedViewModelOrNull() != nil && !refresh) {
            print("Not loading viewmodel. Already loaded!")
            return
        }

        loadViewModel(refresh: refresh)
    }

    func loadViewModel(refresh: Bool) {
        print("Loading viewmodel..")
        shouldRefreshViewModel = false

        listener?.onWillLoadViewModel(willRefresh: refresh)

        controller.loadViewModel(refresh: refresh) { [weak self] _, error in
            self?.listener?.onLoadViewModelCompleted()

            if (error == nil) {
                print("ViewModel loading completed successfully.")
            } else {
                print("ViewModel loading completed with a failure.")
            }
        }
    }

    func onWillLoadViewModel(willRefresh: Bool) {
        listener?.onWillLoadViewModel(willRefresh: willRefresh)
    }

    func onLoadViewModelCompleted() {
        listener?.onLoadViewModelCompleted()
    }

    func onViewModelNotLoaded() {
        print("viewmodel not loaded")
        listener?.onViewModelNotLoaded()
    }

    func onViewModelLoading() {
        print("viewmodel being loaded..")
        listener?.onViewModelLoading()
    }

    func onViewModelLoaded(viewModel: ViewModelType) {
        print("viewmodel loaded")
        listener?.onViewModelLoaded(viewModel: viewModel)
    }

    func onViewModelLoadFailed() {
        print("viewmodel load failed")
        listener?.onViewModelLoadFailed()
    }
}
