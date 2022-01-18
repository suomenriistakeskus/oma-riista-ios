import Foundation
import PhotosUI

@available(iOS 14, *)
class LimitedPhotoLibraryAccessUpdater: PresentedViewControllerDismissObserver, PHPhotoLibraryChangeObserver {

    // keep strong references to updaters so that they won't be garbage collected too soon
    static private var activeUpdaters = Synchronized<Set<LimitedPhotoLibraryAccessUpdater>>(
        label: "LimitedPhotoLibraryAccessUpdater.active",
        initialValue: Set<LimitedPhotoLibraryAccessUpdater>()
    )

    private var completionHandler: (() -> Void)?

    init() {
        super.init(dismissObservationIntervalSeconds: 1.0)
//        self.debugPrint = true
    }

    /**
     * Launches the UI for selecting the photos the app has access to. Does nothing if current authorizationStatus
     * is not .limited.
     *
     * The completion will only be called if user confirms the updated selection (changes are not necessarily made though)
     */
    func present(from parentViewController: UIViewController, completion: (() -> Void)?) {
        // sanity check authorization status since we're about to start
        // observing photo library changes
        if (PHPhotoLibrary.authorizationStatus(for: .readWrite) != .limited) {
            print("Not presenting, authorizationStatus != .limited")
            return
        }

        self.completionHandler = completion
        observePhotoLibraryChanges()

        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: parentViewController)
        startObservePresentedViewControllerDismissal(presentingViewController: parentViewController,
                                                     shouldBePresentingAfterSeconds: 1.0)
    }

    override func onPresentedViewControllerDismissed() {
        stopObservingPhotoLibraryChanges()
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        stopPresentedViewControllerDismissObservation()
        stopObservingPhotoLibraryChanges()

        // photo library was changed. When testing on the device this was also called whenuser confirmed changes
        // even though no no changes were made. On Simulator photoLibraryDidChange is only called when
        // changes are made
        self.completionHandler?()
    }

    func observePhotoLibraryChanges() {
        PHPhotoLibrary.shared().register(self)
        LimitedPhotoLibraryAccessUpdater.activeUpdaters.apply { [self] updaters in
            updaters.insert(self)
        }
    }

    func stopObservingPhotoLibraryChanges() {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        LimitedPhotoLibraryAccessUpdater.activeUpdaters.apply { [self] updaters in
            updaters.remove(self)
        }
    }
}
