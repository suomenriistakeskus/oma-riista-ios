import Foundation
import RiistaCommon

class HuntingLicenseViewController: BaseViewController {

    private lazy var contentView: HuntingLicenseContentView = HuntingLicenseContentView()

    private let userInfo: UserInfo

    @objc init(userInfo: UserInfo) {
        self.userInfo = userInfo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported!")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        contentView.updateValues(user: userInfo)

        title = "MyDetailsTitleHuntingLicense".localized()
    }

    override func loadView() {
        // add constraints according to:
        // https://developer.apple.com/library/archive/technotes/tn2154/_index.html
        view = UIView()

        let scrollView = UIScrollView()
        scrollView.backgroundColor = UIColor.applicationColor(ViewBackground)
        scrollView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        view.addSubview(scrollView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        // the layoutMargins we're setting may be less than system minimum layout margins..
        viewRespectsSystemMinimumLayoutMargins = false

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(scrollView.layoutMarginsGuide)
            make.top.bottom.equalToSuperview().inset(12)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.insuranceInstructionsButton.onClicked = {
            self.openInsuranceInstructions()
        }
    }

    private func openInsuranceInstructions() {
        if let url = URL(string: "MyDetailsInsuranceInstructionsLinkUrl".localized()) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
