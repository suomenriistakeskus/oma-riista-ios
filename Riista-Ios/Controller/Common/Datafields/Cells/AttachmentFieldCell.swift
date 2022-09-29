import Foundation
import SnapKit
import RiistaCommon
import UIKit

protocol AttachmentFieldStatusProvider {
    func getAttachmentDownloadStatus(fieldId: Int) -> DownloadStatus
    func listenForAttachmentDownloadStatusChanges(fieldId: Int, listener: @escaping AttachmentDownloadStatusListener)
}

typealias AttachmentDownloadStatusListener = (_ fieldId: Int, _ downloadStatus: DownloadStatus) -> Void

// use simple typealias for different actions instead of protocols with associated types
// as constraining associated type to FieldId seemed too qumbersome (if possible at all)
typealias AttachmentFieldAction<FieldId : DataFieldId> = (_ fieldId: FieldId) -> Void

class AttachmentFieldCell<FieldId : DataFieldId>:
    TypedDataFieldCell<FieldId, AttachmentField<FieldId>> {


    override var cellType: DataFieldCellType { CELL_TYPE }

    var clickListener: AttachmentFieldAction<FieldId>? = nil
    var removeListener: AttachmentFieldAction<FieldId>? = nil

    var attachmentStatusProvider: AttachmentFieldStatusProvider?

    private lazy var topLevelContainer: OverlayStackView = {
        let container = OverlayStackView()
        container.axis = .horizontal
        container.alignment = .center

        container.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall).priority(999)
        }
        return container
    }()

    override var containerView: UIView {
        topLevelContainer
    }

    private lazy var iconImageView: UIImageView = {
        let imageView = ImageViewWithRoundedCorners()
        imageView.contentMode = .scaleAspectFill
        imageView.roundedCorners = .allCorners()
        imageView.cornerRadius = 4
        imageView.clipsToBounds = true

        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(48)
        }

        imageView.addSubview(downloadIndicatorImageView)
        downloadIndicatorImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        return imageView
    }()

    private lazy var downloadIndicatorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.backgroundColor = DOWNLOAD_INDICATOR_BG_COLOR_NOT_DOWNLOADING

        imageView.addSubview(downloadIndicatorProgressLabel)
        downloadIndicatorProgressLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        return imageView
    }()

    private lazy var downloadIndicatorProgressLabel: UILabel = {
        let label = UILabel().configure(
            fontSize: .medium,
            fontWeight: .semibold,
            textColor: .white
        )
        label.isHidden = true
        return label
    }()

    private lazy var titleLabel: UILabel = {
        UILabel().configure(fontSize: .small)
    }()

    private lazy var removeButton: MaterialButton = {
        let button = MaterialButton()
        button.setImage(UIImage(named: "cross"), for: .normal)
        button.applyTextTheme(withScheme: AppTheme.shared.buttonContainerScheme())
        button.onClicked = { [weak self] in
            self?.onRemoveClicked()
        }
        button.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(48).priority(999)
        }
        return button
    }()

    override func createSubviews(for container: UIView) {
        guard let container = container as? OverlayStackView else {
            fatalError("Expected OverlayStackView as container!")
        }

        // add clickable background directly to contentView
        let background = ClickableCellBackground()
        background.onClicked = { [weak self] in
            self?.onClicked()
        }
        contentView.insertSubview(background, at: 0)
        background.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        container.addView(iconImageView)
        container.addSpacer(size: 12, canExpand: false)
        container.addView(titleLabel)
        container.addSpacer(size: 8, canExpand: true)
        container.addView(removeButton)
    }

    override func fieldWasBound(field: AttachmentField<FieldId>) {
        titleLabel.text = field.filename
        if let thumbnailBase64 = field.thumbnailBase64,
            let imageData = Data(base64Encoded: thumbnailBase64),
            let image = UIImage(data: imageData) {

            iconImageView.image = image
            iconImageView.tintColor = nil
        } else {
            iconImageView.image = ATTACHMENT_IMAGE
            iconImageView.tintColor = UIColor.applicationColor(Primary)
        }

        removeButton.isHidden = field.settings.readOnly

        if let attachmentStatusProvider = attachmentStatusProvider {
            attachmentStatusProvider.listenForAttachmentDownloadStatusChanges(
                fieldId: Int(field.id_.toInt())
            ) { [weak self] fieldId, downloadStatus in
                self?.onAttachmentDownloadStatusChanged(fieldId: fieldId, downloadStatus: downloadStatus)
            }

            let downloadStatus = attachmentStatusProvider.getAttachmentDownloadStatus(fieldId: Int(field.id_.toInt()))
            indicateDownloadStatus(downloadStatus: downloadStatus, animate: false)
        }
    }

    private func onClicked() {
        guard let field = boundField else {
            print("No bound attachment field, cannot handle click")
            return
        }

        clickListener?(field.id_)
    }

    private func onRemoveClicked() {
        guard let field = boundField else {
            print("No bound attachment field, cannot handle remove button click")
            return
        }

        removeListener?(field.id_)
    }

    private func onAttachmentDownloadStatusChanged(fieldId: Int, downloadStatus: DownloadStatus) {
        guard let boundFieldId = boundField?.id_.toInt() else {
            print("No bound field, cannot update download status")
            return
        }

        if (fieldId != boundFieldId) {
            print("Got download status update but it was meant for some other field")
            return
        }

        indicateDownloadStatus(downloadStatus: downloadStatus, animate: true)
    }

    private func indicateDownloadStatus(downloadStatus: DownloadStatus, animate: Bool) {
        switch downloadStatus {
        case .notDownloaded:
            if (!downloadIndicatorImageView.isAnimatingView()) {
                UIView.animate(withDuration: AppConstants.Animations.durationShort) {
                    self.downloadIndicatorImageView.backgroundColor = DOWNLOAD_INDICATOR_BG_COLOR_NOT_DOWNLOADING
                }
            } else {
                self.downloadIndicatorImageView.backgroundColor = DOWNLOAD_INDICATOR_BG_COLOR_NOT_DOWNLOADING
            }
            downloadIndicatorImageView.image = NOT_DOWNLOADED_IMAGE
            downloadIndicatorImageView.isHidden = false
            downloadIndicatorImageView.alpha = 1
            downloadIndicatorProgressLabel.isHidden = true
        case .downloading(let progress):
            if (!downloadIndicatorImageView.isAnimatingView()) {
                UIView.animate(withDuration: AppConstants.Animations.durationShort) {
                    self.downloadIndicatorImageView.backgroundColor = DOWNLOAD_INDICATOR_BG_COLOR_DOWNLOADING
                }
            } else {
                self.downloadIndicatorImageView.backgroundColor = DOWNLOAD_INDICATOR_BG_COLOR_DOWNLOADING
            }
            downloadIndicatorImageView.image = nil
            downloadIndicatorImageView.isHidden = false
            downloadIndicatorImageView.alpha = 1

            downloadIndicatorProgressLabel.isHidden = false
            downloadIndicatorProgressLabel.text = "\(Int(progress.fractionCompleted * 100))%"
        case .downloaded:
            if (animate) {
                downloadIndicatorImageView.isHidden = false
                downloadIndicatorImageView.alpha = 1
                UIView.animate(withDuration: AppConstants.Animations.durationShort) {
                    self.downloadIndicatorImageView.alpha = 0
                    self.downloadIndicatorImageView.backgroundColor = DOWNLOAD_INDICATOR_BG_COLOR_NOT_DOWNLOADING
                } completion: { _ in
                    self.downloadIndicatorImageView.image = nil
                    self.downloadIndicatorImageView.isHidden = true
                    self.downloadIndicatorProgressLabel.isHidden = true
                }
            } else {
                downloadIndicatorImageView.image = nil
                downloadIndicatorImageView.isHidden = true
                downloadIndicatorProgressLabel.isHidden = true
            }

        }
    }

    class Factory<FieldId : DataFieldId>: DataFieldCellFactory<FieldId> {

        var clickListener: AttachmentFieldAction<FieldId>? = nil
        var removeListener: AttachmentFieldAction<FieldId>? = nil
        var attachmentStatusProvider: AttachmentFieldStatusProvider? = nil

        init(
            clickListener: AttachmentFieldAction<FieldId>?,
            removeListener: AttachmentFieldAction<FieldId>?,
            attachmentStatusProvider: AttachmentFieldStatusProvider?
        ) {
            self.clickListener = clickListener
            self.removeListener = removeListener
            self.attachmentStatusProvider = attachmentStatusProvider

            super.init(cellType: CELL_TYPE)
        }

        override func registerCellType(to tableView: UITableView) {
            tableView.register(
                AttachmentFieldCell<FieldId>.self,
                forCellReuseIdentifier: CELL_TYPE.reuseIdentifier
            )
        }

        override func createCell(for tableView: UITableView, indexPath: IndexPath, dataField: DataField<FieldId>) -> DataFieldCell<FieldId> {
            let cell = tableView.dequeueReusableCell(
                    withIdentifier: CELL_TYPE.reuseIdentifier,
                    for: indexPath
            ) as! AttachmentFieldCell<FieldId>

            cell.clickListener = clickListener
            cell.removeListener = removeListener
            cell.attachmentStatusProvider = attachmentStatusProvider

            return cell
        }
    }
}

fileprivate let CELL_TYPE = DataFieldCellType.attachment
fileprivate let ATTACHMENT_IMAGE = UIImage(named: "text_snippet_36pt")
fileprivate let NOT_DOWNLOADED_IMAGE = UIImage(named: "file_download")
fileprivate let DOWNLOAD_INDICATOR_BG_COLOR_NOT_DOWNLOADING: UIColor = .black.withAlphaComponent(0.5)
fileprivate let DOWNLOAD_INDICATOR_BG_COLOR_DOWNLOADING: UIColor = .black.withAlphaComponent(0.7)
