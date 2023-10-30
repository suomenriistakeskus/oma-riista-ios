import Foundation
import UIKit
import RiistaCommon


/**
 * A base viewcontroller that will contain the common code needed when using RiistaCommon.ControllerWithLoadableModel.
 *
 * Assumes that the ViewController is instantiated programmatically (creates a dummy view in loadView()).
 */
class BaseControllerWithViewModel<ViewModelType, Controller : ControllerWithLoadableModel<ViewModelType>>
        : BaseViewController, ListensViewModelStatusChanges {

    var controller: Controller {
        get {
            fatalError("implement controller in subclass")
        }
    }

    lazy var controllerHolder: ControllerHolder<ViewModelType, Controller, BaseControllerWithViewModel<ViewModelType, Controller>> = {
        return ControllerHolder(controller: controller, listener: self)
    }()

    /**
     * A flag for instructing the viewmodel to be refreshed next time the viewcontroller appears
     * (viewWillAppear is called).
     *
     * Allows e.g. refetching data from the backend after other views possibly have made changes to the content.
     * The flag is cleared when viewmodel is being loaded (success is not required).
     */
    internal var shouldRefreshViewModel: Bool {
        get {
            return controllerHolder.shouldRefreshViewModel
        }
        set(value) {
            controllerHolder.shouldRefreshViewModel = value
        }
    }

    private(set) var refreshIndicator: LoadIndicatorViewController?

    /**
     * Should the above mentioned `refreshIndicator` be used for indicating `loading` state.
     */
    var indicateLoadingStateUsingRefreshIndicator: Bool = true

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onViewWillAppear()
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onViewWillDisappear()
    }

    /**
     * ControllerHolder usage moved to a custom function in order to better allow subclasses
     * to do things differently (they should call super.viewWillAppear) but they are not required
     * to call super.onViewWillAppear())
     */
    func onViewWillAppear() {
        controllerHolder.onViewWillAppear()
    }

    /**
     * ControllerHolder usage moved to a custom function in order to better allow subclasses
     * to do things differently (they should call super.viewWillDisappear) but they are not required
     * to call super.onViewWillDisappear())
     */
    func onViewWillDisappear() {
        controllerHolder.onViewWillDisappear()
    }

    func onWillLoadViewModel(willRefresh: Bool) {
        if (willRefresh && indicateLoadingStateUsingRefreshIndicator) {
            refreshIndicator = LoadIndicatorViewController().showIn(parentViewController: self)
        }
    }

    func onLoadViewModelCompleted() {
        refreshIndicator?.hide()
        refreshIndicator = nil
    }

    func onViewModelNotLoaded() {
        print("viewmodel not loaded")
    }

    func onViewModelLoading() {
        print("viewmodel loading..")
    }

    func onViewModelLoaded(viewModel: ViewModelType) {
        print("viewmodel loaded")
    }

    func onViewModelLoadFailed() {
        print("viewmodel load failed")
    }

    open override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor.applicationColor(ViewBackground)
    }
}
