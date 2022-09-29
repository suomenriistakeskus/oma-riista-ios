import Foundation
import RiistaCommon


class HuntingControlAttachmentOpenHelper {
    let fileOpenHelper: FileOpenHelper

    init(parentViewController: UIViewController) {
        self.fileOpenHelper = FileOpenHelper(
            parentViewController: parentViewController,
            fileSearchDirectories: [.attachments],
            askDownloadTitle: "AreYouSure".localized(),
            askDownloadMessage: "HuntingControlDownloadAttachmentQuestion".localized()
        )
    }

    func openAttachment(attachment: HuntingControlAttachment) {
        let fileUuid = getAttachmentUuidOrStableId(attachment: attachment)

        let fileDownloadUrl: URL? = attachment.remoteId.flatMap { remoteId in
            URL(string: "\(Environment.serverBaseAddress)/api/mobile/v2/huntingcontrol/attachment/\(remoteId)/download")
        }

        fileOpenHelper.tryOpenFile(
            fileUuid: fileUuid,
            filename: attachment.fileName,
            fileDownloadUrl: fileDownloadUrl
        )
    }

    func getAttachmentDownloadStatus(attachment: HuntingControlAttachment) -> DownloadStatus {
        let fileUuid = getAttachmentUuidOrStableId(attachment: attachment)
        return fileOpenHelper.getFileDownloadStatus(fileUuid: fileUuid)
    }

    func listenForAttachmentDownloadStatusChanges(
        fieldId: Int,
        attachment: HuntingControlAttachment,
        listener: @escaping AttachmentDownloadStatusListener
    ) {
        let attachmentFileUuid = getAttachmentUuidOrStableId(attachment: attachment)
        fileOpenHelper.listenForDownloadStatusChanges(fileUuid: attachmentFileUuid) { [weak self] fileUuid, downloadStatus in
            if (attachmentFileUuid != fileUuid) {
                self?.fileOpenHelper.clearListener(fileUuid: fileUuid)
                return
            }

            listener(fieldId, downloadStatus)
        }
    }

    func cancelAttachmentDownload(attachment: HuntingControlAttachment) {
        let fileUuid = getAttachmentUuidOrStableId(attachment: attachment)
        fileOpenHelper.fileDownloader.cancelFileDownload(fileUuid: fileUuid)
    }


    private func getAttachmentUuidOrStableId(attachment: HuntingControlAttachment) -> String {
        // fallback to fake uuid if real uuid is not available. This is the case when attachment is made on
        // other device / web and we don't have local file for it.
        return attachment.uuid ?? "\(attachment.localId?.stringValue ?? "l")_\(attachment.fileName)"
    }
}
