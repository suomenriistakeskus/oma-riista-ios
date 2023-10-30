import Foundation
import UIKit

fileprivate enum AboutItemType {
    case privacyStatement
    case termsOfService
    case accessibility
    case licenses
}

fileprivate struct AboutItem {
    let type: AboutItemType
    let iconResource: String
    let titleResource: String
    let opensInBrowser: Bool

    init(_ type: AboutItemType, iconResource: String, titleResource: String, opensInBrowser: Bool = false) {
        self.type = type
        self.iconResource = iconResource
        self.titleResource = titleResource
        self.opensInBrowser = opensInBrowser
    }
}

class AboutItemCell: UITableViewCell {
    static let REUSE_IDENTIFIER = "AboutItemCell"

    let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.applicationColor(Primary)
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }
        return imageView
    }()
    let titleView: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.numberOfLines = 0
        return label
    }()
    let opensInBrowserIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.applicationColor(Primary)
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }
        imageView.image = UIImage(named: "open_in_browser")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.applicationColor(Primary)
        return imageView
    }()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(iconView)
        contentView.addSubview(titleView)
        contentView.addSubview(opensInBrowserIndicator)

        iconView.snp.makeConstraints { make in
            make.leading.equalTo(20)
            make.centerY.equalTo(titleView)
        }
        titleView.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(20)
            make.trailing.equalTo(opensInBrowserIndicator.snp.leading).offset(-20)
            make.top.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(AppConstants.UI.DefaultButtonHeight).priority(999)
        }
        opensInBrowserIndicator.snp.makeConstraints { make in
            make.trailing.equalTo(-20)
            make.centerY.equalTo(titleView)
        }

        separatorInset = UIEdgeInsets(top: 0, left: AppConstants.UI.DefaultHorizontalInset,
                                      bottom: 0, right: AppConstants.UI.DefaultHorizontalInset)
    }

    fileprivate func setup(item: AboutItem) {
        iconView.image = UIImage(named: item.iconResource)?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = UIColor.applicationColor(Primary)
        titleView.text = item.titleResource.localized()

        if (item.opensInBrowser) {
            opensInBrowserIndicator.isHidden = false
        } else {
            opensInBrowserIndicator.isHidden = true
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class AboutViewController: UITableViewController {

    private lazy var logger = AppLogger(for: AboutViewController.self, printTimeStamps: false)

    private var aboutItems = [AboutItem]()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "MenuAbout".localized()

        tableView.layoutMargins = AppConstants.UI.DefaultHorizontalEdgeInsets
        tableView.separatorStyle = .singleLine
        tableView.estimatedRowHeight = AppConstants.UI.DefaultButtonHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.register(AboutItemCell.self, forCellReuseIdentifier: AboutItemCell.REUSE_IDENTIFIER)

        initializeAboutItems()
    }

    private func initializeAboutItems() {
        aboutItems.append(AboutItem(.privacyStatement, iconResource: "about_privacy", titleResource: "PrivacyStatement", opensInBrowser: true))
        aboutItems.append(AboutItem(.termsOfService, iconResource: "about_terms_of_service", titleResource: "TermsOfService", opensInBrowser: true))
        aboutItems.append(AboutItem(.accessibility, iconResource: "about_accessibility", titleResource: "AccessibilityStatement", opensInBrowser: true))
        aboutItems.append(AboutItem(.licenses, iconResource: "about_licenses", titleResource: "ThirdPartyLibraries"))
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        aboutItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: AboutItemCell.REUSE_IDENTIFIER) as? AboutItemCell
        if (cell == nil) {
            cell = AboutItemCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: AboutItemCell.REUSE_IDENTIFIER)
        }
        cell?.setup(item: aboutItems[indexPath.row])

        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = aboutItems[indexPath.row]
        onItemClicked(item)
        tableView.deselectRow(at: indexPath, animated: false)
    }

    private func onItemClicked(_ item: AboutItem) {
        switch item.type {
        case .privacyStatement:
            self.openUrl(urlLocalizationKey: "PrivacyStatementUrl")
            break
        case .termsOfService:
            self.openUrl(urlLocalizationKey: "TermsOfServiceUrl")
            break
        case .accessibility:
            self.openUrl(urlLocalizationKey: "AccessibilityStatementUrl")
            break
        case .licenses:
            showThirdPartyLibraries()
            break
        }
    }

    private func showThirdPartyLibraries() {
        let viewController = ThirdPartyLicensesController()
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    private func openUrl(urlLocalizationKey: String) {
        guard let url = URL(string: urlLocalizationKey.localized()) else {
            logger.w { "Failed to obtain url for localization key \(urlLocalizationKey)" }
            return
        }

        UIApplication.shared.open(url)
    }
}
