import Foundation
import MobileCoreServices

extension URL {

    func fileUti() -> String? {
        return uti() as? String
    }

    func mimeType() -> String {
        if let uti = uti() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }

    private func uti() -> CFString? {
        let pathExtension = self.pathExtension as NSString
        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)
        return uti?.takeRetainedValue()
    }

}
