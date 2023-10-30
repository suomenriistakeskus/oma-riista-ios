import Foundation
import SnapKit

protocol ChangeUsernameViewControllerDelegate: AnyObject {
    func cancelChangeUserName()
    func startRegistration()
}

class ChangeUsernameViewController: BaseViewController {

    weak var delegate: ChangeUsernameViewControllerDelegate?


    private lazy var changeUsernameView: ChangeUsernameView = {
        let view = ChangeUsernameView()
        view.startRegistrationButton.onClicked = { [weak self] in
            self?.delegate?.startRegistration()
        }
        view.cancelButton.onClicked = { [weak self] in
            self?.delegate?.cancelChangeUserName()
        }
        return view
    }()

    // MARK: Creating views

    override func loadView() {
        view = UIView()

        let container = UIView()
        container.backgroundColor = .black.withAlphaComponent(0.7)

        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview().inset(AuthenticationUiConstants.horizontalMarginsToScreen)
            make.top.greaterThanOrEqualToSuperview()
        }

        container.addSubview(changeUsernameView)
        changeUsernameView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
