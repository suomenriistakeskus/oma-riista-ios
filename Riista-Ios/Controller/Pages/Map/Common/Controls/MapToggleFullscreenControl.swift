import Foundation

class MapToggleFullscreenControl: BaseMapControl {

    private weak var viewController: UIViewController?

    private weak var toggleFullscreenButton: MaterialButton?

    private(set) var isFullscreen: Bool = false
    private var viewControllerHeightBeforeFullScreen: CGFloat = 0

    init(viewController: UIViewController) {
        super.init(type: .toggleFullscreen)
        self.viewController = viewController
    }

    override func onViewWillDisappear() {
        super.onViewWillDisappear()

        exitFullscreen()
    }

    func exitFullscreen() {
        if (isFullscreen) {
            toggleFullscreen()
        }
    }

    private func toggleFullscreen() {
        isFullscreen = !isFullscreen

        // used in animations, isFullscreen may change while animating
        let fullscreen = isFullscreen
        UIView.animate(withDuration: AppConstants.Animations.durationShort) { [weak self] in
            guard let self = self, let viewController = self.viewController else {
                return
            }

            if (self.viewControllerHeightBeforeFullScreen < 1) {
                self.viewControllerHeightBeforeFullScreen = viewController.view.frame.height
            }

            if (!fullscreen) {
                // setNeedsStatusBarAppearanceUpdate will only update status bar appearance
                // if navigation bar has been hidden with setNavigationBarHidden:YES
                // -> if exiting fullscreen make the call when we're still in hidden state
                //    or otherwise statusbar appearance won't get updated
                viewController.setNeedsStatusBarAppearanceUpdate();
            }

            if let presentingViewController = viewController.presentingViewController {
                presentingViewController.navigationController?.setNavigationBarHidden(fullscreen, animated: true)

                if let tabBarController = presentingViewController.tabBarController {
                    self.updateTabBarVisibility(tabBarController: tabBarController, fullscreen: fullscreen)
                }
            } else {
                viewController.navigationController?.setNavigationBarHidden(fullscreen, animated: true)
                if let tabBarController = viewController.tabBarController {
                    self.updateTabBarVisibility(tabBarController: tabBarController, fullscreen: fullscreen)
                }
            }

            if (fullscreen) {
                // setNeedsStatusBarAppearanceUpdate will only update status bar appearance
                // if navigation bar has been hidden with setNavigationBarHidden:YES
                viewController.setNeedsStatusBarAppearanceUpdate()
            } else {
                // exiting fullscreen -> clear height before fullscreen so that it gets reinitialized
                // before when entering fullscreen next time
                self.viewControllerHeightBeforeFullScreen = 0;
            }
        }

        updateToggleButtonImage()
    }

    private func updateTabBarVisibility(tabBarController: UITabBarController, fullscreen: Bool) {
        tabBarController.tabBar.isHidden = fullscreen
        tabBarController.tabBar.isUserInteractionEnabled = !fullscreen

        // move bottom only when displaying as a tab
        guard let viewController = self.viewController else {
            return
        }

        let windowHeight = viewController.view.window!.frame.height
        var frame = viewController.view.frame
        frame.size.height = fullscreen
            ? windowHeight
            : self.viewControllerHeightBeforeFullScreen

        viewController.view.frame = frame
    }

    override func registerControls(overlayControlsView: MapControlsOverlayView) {
        let image = getCurrentStateImage()
        toggleFullscreenButton = overlayControlsView.addEdgeControl(image: image) { [weak self] in
            self?.toggleFullscreen()
        }
    }

    private func updateToggleButtonImage() {
        toggleFullscreenButton?.setImage(getCurrentStateImage(), for: .normal)
    }

    private func getCurrentStateImage() -> UIImage? {
        return UIImage(named: isFullscreen ? "collapse" : "expand")
    }
}
