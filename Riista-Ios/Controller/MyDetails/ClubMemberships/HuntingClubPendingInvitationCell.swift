import Foundation
import MaterialComponents
import RiistaCommon

protocol HuntingClubInvitationActionListener: AnyObject {
    func onAcceptInvitationRequested(invitation: HuntingClubViewModel.Invitation)
    func onRejectInvitationRequested(invitation: HuntingClubViewModel.Invitation)
}

class HuntingClubPendingInvitationCell: UITableViewCell {
    static let reuseIdentifier = "HuntingClubPendingInvitationCell"

    private lazy var clubNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(fontSize: .small, fontWeight: .semibold)
        label.textColor = UIColor.applicationColor(TextPrimary)
        label.numberOfLines = 0
        return label
    }()

    private lazy var clubNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.appFont(for: .label, fontWeight: .regular)
        label.textColor = UIColor.applicationColor(Primary)
        label.numberOfLines = 0
        return label
    }()

    private lazy var acceptButton: MaterialButton = {
        let button = MaterialButton()
        button.setTitle("HuntingClubMembershipAcceptInvitation".localized(), for: .normal)
        button.applyContainedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        button.onClicked = { [weak self] in
            self?.onRequestAcceptInvitation()
        }

        button.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        return button
    }()

    private lazy var rejectButton: MaterialButton = {
        let button = MaterialButton()
        button.setTitle("HuntingClubMembershipRejectInvitation".localized(), for: .normal)
        button.applyOutlinedTheme(withScheme: AppTheme.shared.primaryButtonScheme())
        button.onClicked = { [weak self] in
            self?.onRequestRejectInvitation()
        }

        button.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }
        return button
    }()

    weak var actionListener: HuntingClubInvitationActionListener?
    private var boundInvitation: HuntingClubViewModel.Invitation?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func bind(invitation: HuntingClubViewModel.Invitation) {
        clubNumberLabel.text = String(format: "HuntingClubOccupationCode".localized(), invitation.officialCode)
        clubNameLabel.text = invitation.name

        boundInvitation = invitation
    }

    private func onRequestAcceptInvitation() {
        guard let listener = actionListener, let invitation = boundInvitation else {
            return
        }

        listener.onAcceptInvitationRequested(invitation: invitation)
    }

    private func onRequestRejectInvitation() {
        guard let listener = actionListener, let invitation = boundInvitation else {
            return
        }

        listener.onRejectInvitationRequested(invitation: invitation)
    }

    private func commonInit() {
        let viewContainer = OverlayStackView()
        viewContainer.axis = .vertical
        viewContainer.alignment = .fill
        viewContainer.spacing = 4
        contentView.addSubview(viewContainer)

        viewContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(12)
        }

        viewContainer.addView(clubNumberLabel)
        viewContainer.addView(clubNameLabel, spaceAfter: 12)
        viewContainer.addView(acceptButton, spaceAfter: 8)
        viewContainer.addView(rejectButton)
    }
}

