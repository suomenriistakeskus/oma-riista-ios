import Foundation
import Alamofire
import MaterialComponents
import RiistaCommon

enum DownloadStatus {
    case notDownloaded
    case downloading(progress: Progress)
    case downloaded
}

typealias FileDownloadStatusListener = (_ fileUuid: String, _ downloadStatus: DownloadStatus) -> Void

class FileDownloader: NSObject, UIDocumentInteractionControllerDelegate {
    static let DOWNLOAD_DIRECTORY: CommonFileProviderDirectory = .temporaryFiles

    // not-thread safe, use cautiously!
    static let shared: FileDownloader = FileDownloader()

    private var downloadRequests: [String : DownloadRequest] = [:]
    private var downloadStatusListeners: [String : FileDownloadStatusListener] = [:]


    func getFileDownloadStatus(fileUuid: String) -> DownloadStatus? {
        if let downloadProgress = downloadRequests[fileUuid]?.downloadProgress {
            return .downloading(progress: downloadProgress)
        }

        return nil
    }

    func listenForDownloadStatusChanges(fileUuid: String, listener: @escaping FileDownloadStatusListener) {
        downloadStatusListeners[fileUuid] = listener
    }

    func clearListener(fileUuid: String) {
        downloadStatusListeners.removeValue(forKey: fileUuid)
    }

    func downloadFile(
        fileDownloadUrl: URL?,
        fileUuid: String,
        onDownloadCompleted: @escaping OnCompletedWithStatus
    ) {
        guard let fileDownloadUrl = fileDownloadUrl else {
            print("No download url, refusing to attempt downloading")
            onDownloadCompleted(false)
            return
        }

        guard let targetFilePath = CommonFileStorage.shared.getPathFor(
            directory: FileDownloader.DOWNLOAD_DIRECTORY,
            fileUuid: fileUuid
        ) else {
            print("Failed to obtain target file path")
            onDownloadCompleted(false)
            return
        }

        let destination: DownloadRequest.Destination = { _, _ in
            (URL(fileURLWithPath: targetFilePath), [.removePreviousFile, .createIntermediateDirectories])
        }

        let downloadRequest = AF.download(fileDownloadUrl, to: destination)
            .downloadProgress { [weak self] progress in
                self?.notifyListener(
                    fileUuid: fileUuid,
                    downloadStatus: .downloading(progress: progress)
                )
            }
            .response { [weak self] response in
                let statusCode = response.response?.statusCode ?? -1
                let wasSuccess = response.error == nil && (200...300).contains(statusCode)

                self?.downloadRequests.removeValue(forKey: fileUuid)
                self?.notifyListener(fileUuid: fileUuid, downloadStatus: wasSuccess ? .downloaded : .notDownloaded)

                onDownloadCompleted(wasSuccess)
            }

        let progress = Progress()
        progress.totalUnitCount = 100
        progress.completedUnitCount = 0

        notifyListener(
            fileUuid: fileUuid,
            downloadStatus: .downloading(progress: progress)
        )
        downloadRequests[fileUuid] = downloadRequest
    }

    func cancelFileDownload(fileUuid: String) {
        guard let downloadRequest = downloadRequests[fileUuid] else {
            print("No download request for file \(fileUuid), cannot cancel")
            return
        }

        print("Cancelling file \(fileUuid) download..")
        downloadRequests.removeValue(forKey: fileUuid)

        downloadRequest.cancel { data in
            // remove the file
            guard let filePath = CommonFileStorage.shared.getPathFor(
                directory: FileDownloader.DOWNLOAD_DIRECTORY,
                fileUuid: fileUuid
            ) else {
                print("cancelFileDownload: Failed to obtain file path")
                return
            }

            print("File \(fileUuid) download cancelled. Trying to remove the file.")
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: filePath))
        }

    }

    private func notifyListener(fileUuid: String, downloadStatus: DownloadStatus) {
        if let listener = downloadStatusListeners[fileUuid] {
            listener(fileUuid, downloadStatus)
        }
    }
}
