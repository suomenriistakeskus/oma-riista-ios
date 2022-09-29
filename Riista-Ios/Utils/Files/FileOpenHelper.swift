import Foundation
import Alamofire
import MaterialComponents
import RiistaCommon

class FileOpenHelper: NSObject, UIDocumentInteractionControllerDelegate {
    let parentViewController: UIViewController
    let fileSearchDirectories: [CommonFileProviderDirectory]
    let askDownloadTitle: String
    let askDownloadMessage: String
    var documentInteractionController: UIDocumentInteractionController?

    let fileDownloader: FileDownloader = FileDownloader.shared

    init(parentViewController: UIViewController,
         fileSearchDirectories: [CommonFileProviderDirectory],
         askDownloadTitle: String,
         askDownloadMessage: String
    ) {
        self.parentViewController = parentViewController
        self.askDownloadTitle = askDownloadTitle
        self.askDownloadMessage = askDownloadMessage
        self.fileSearchDirectories = fileSearchDirectories + [FileDownloader.DOWNLOAD_DIRECTORY]
    }

    func getFileDownloadStatus(fileUuid: String) -> DownloadStatus {
        if let downloadStatus = fileDownloader.getFileDownloadStatus(fileUuid: fileUuid) {
            return downloadStatus
        }

        if (findLocalFile(searchDirectories: fileSearchDirectories, fileUuid: fileUuid) != nil) {
            return .downloaded
        } else {
            return .notDownloaded
        }
    }

    func listenForDownloadStatusChanges(fileUuid: String, listener: @escaping FileDownloadStatusListener) {
        fileDownloader.listenForDownloadStatusChanges(fileUuid: fileUuid, listener: listener)
    }

    func clearListener(fileUuid: String) {
        fileDownloader.clearListener(fileUuid: fileUuid)
    }

    /**
     * Tries to open specified file located at given directory. In addition to given directory will search the file
     * from .temporaryFiles directory.
     *
     * Will try to download file if no local version exists. The downloaded file will be located in .temporaryFiles.
     */
    func tryOpenFile(
        fileUuid: String,
        filename: String?,
        fileDownloadUrl: URL?
    ) {
        if (tryOpenLocalFile(searchDirectories: fileSearchDirectories, fileUuid: fileUuid, filename: filename)) {
            return
        }

        let currentDownloadStatus = getFileDownloadStatus(fileUuid: fileUuid)
        if case .downloading = currentDownloadStatus {
            askCancelDownloadConfirmation(fileUuid: fileUuid)
            return
        }

        askDownloadConfirmation(
            fileDownloadUrl: fileDownloadUrl,
            fileUuid: fileUuid
        ) { [weak self] fileDownloaded in
            if (!fileDownloaded) {
                return
            }

            self?.tryOpenLocalFile(searchDirectories: [FileDownloader.DOWNLOAD_DIRECTORY], fileUuid: fileUuid, filename: filename)
        }
    }

    @discardableResult
    private func tryOpenLocalFile(
        searchDirectories: [CommonFileProviderDirectory],
        fileUuid: String,
        filename: String?
    ) -> Bool {
        guard let file = findLocalFile(searchDirectories: searchDirectories, fileUuid: fileUuid) else {
            print("No file for uuid = \(fileUuid), cannot open")
            return false
        }

        var fileUrl = URL(fileURLWithPath: file.path)
        if let filename = filename {
            let targetFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

            // only copy file to temporary directory if it isn't there already because
            // the target file is removed beforehand
            if (fileUrl != targetFileUrl) {
                do {
                    // ignore remove failure
                    try? FileManager.default.removeItem(at: targetFileUrl)

                    // create copy to temporary
                    try FileManager.default.copyItem(at: fileUrl, to: targetFileUrl)
                    fileUrl = targetFileUrl
                } catch {
                    // nop
                }
            } else {
                print("File is already located in the given url!")
            }
        }

        let fileUti: String? = filename.flatMap { URL(fileURLWithPath: $0).fileUti() }

        let documentController = UIDocumentInteractionController(url: fileUrl)
        documentController.uti = fileUti
        documentController.name = filename
        documentController.delegate = self
        self.documentInteractionController = documentController
        return documentController.presentOptionsMenu(from: .zero, in: parentViewController.view, animated: true)
    }

    private func findLocalFile(
        searchDirectories: [CommonFileProviderDirectory],
        fileUuid: String
    ) -> CommonFile? {
        let file: CommonFile? = searchDirectories.firstResult { directory in
            print("Finding file \(fileUuid) from \(directory)")

            guard let file = CommonFileStorage.shared.getFile(directory: directory, fileUuid: fileUuid) else {
                print("No file for uuid = \(fileUuid), cannot open")
                return nil
            }

            if (!file.exists()) {
                return nil
            }

            return file
        }

        return file
    }

    func askDownloadConfirmation(
        fileDownloadUrl: URL?,
        fileUuid: String,
        onDownloadCompleted: @escaping OnCompletedWithStatus
    ) {
        let alertController = MDCAlertController(title: askDownloadTitle, message: askDownloadMessage)
        alertController.addAction(MDCAlertAction(title: "Yes".localized(), handler: { [weak self] _ in
            guard let self = self else { return }

            self.fileDownloader.downloadFile(
                fileDownloadUrl: fileDownloadUrl,
                fileUuid: fileUuid,
                onDownloadCompleted: onDownloadCompleted
            )
        }))
        alertController.addAction(MDCAlertAction(title: "No".localized(), handler: nil))

        parentViewController.present(alertController, animated: true, completion: nil)
    }

    func askCancelDownloadConfirmation(
        fileUuid: String
    ) {
        let alertController = MDCAlertController(title: "FileCancelDownloadQuestion".localized(), message: nil)
        alertController.addAction(MDCAlertAction(title: "Yes".localized(), handler: { [weak self] _ in
            guard let self = self else { return }
            self.fileDownloader.cancelFileDownload(fileUuid: fileUuid)
        }))
        alertController.addAction(MDCAlertAction(title: "No".localized(), handler: nil))

        parentViewController.present(alertController, animated: true, completion: nil)
    }

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        parentViewController
    }
}
