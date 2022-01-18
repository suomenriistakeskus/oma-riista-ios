import Foundation

/**
 * Wraps the necessary information to uniquely identify an image.
 */
@objc public class ImageIdentifier: NSObject {
    @objc var imageUrl: URL? {
        get {
            switch identifyingData {
            case .localIdentifier(_):
                return nil
            case .imageUrl(let url):
                return url
            case .localIdentifierAndUrl(_, let url):
                return url
            }
        }
    }

    @objc var localIdentifier: String? {
        get {
            switch identifyingData {
            case .localIdentifier(let localIdentifier):
                return localIdentifier
            case .imageUrl(_):
                return nil
            case .localIdentifierAndUrl(let localIdentifier, _):
                return localIdentifier
            }
        }
    }

    enum IdentifyingData {
        case localIdentifier(localIdentifier: String)
        case imageUrl(url: URL)
        case localIdentifierAndUrl(localIdentifier: String, url: URL)
    }

    // encapsulate the actual identifying data into enum. This prevents creating invalid ImageIdentifier
    // as ImageIdentifier is guaranteed to have valid IdentifyingData and IdentifyingData is guaranteed
    // to have either valid localIdentifier or valid url (or both).
    let identifyingData: IdentifyingData

    init(identifyingData: IdentifyingData) {
        self.identifyingData = identifyingData
    }

    @objc class func create(imageUrl: String?) -> ImageIdentifier? {
        guard let url = getURL(urlString: imageUrl) else {
            return nil
        }

        return ImageIdentifier(identifyingData: .imageUrl(url: url))
    }

    @objc class func create(localIdentifier: String?) -> ImageIdentifier? {
        guard let localIdentifier = localIdentifier else {
            return nil
        }

        return ImageIdentifier(identifyingData: .localIdentifier(localIdentifier: localIdentifier))
    }

    @objc class func create(localIdentifier: String?, imageUrl: String?) -> ImageIdentifier? {
        if let validLocalIdentifier = localIdentifier {
            return create(validLocalIdentifier: validLocalIdentifier, imageUrl: imageUrl)
        } else if let url = getURL(urlString: imageUrl) {
            return ImageIdentifier(identifyingData: .imageUrl(url: url))
        } else {
            return nil
        }
    }

    @objc class func create(validLocalIdentifier: String, imageUrl: String?) -> ImageIdentifier {
        let url = getURL(urlString: imageUrl)

        if let url = url {
            return ImageIdentifier(identifyingData: .localIdentifierAndUrl(localIdentifier: validLocalIdentifier, url: url))
        } else {
            return ImageIdentifier(identifyingData: .localIdentifier(localIdentifier: validLocalIdentifier))
        }
    }

    private class func getURL(urlString: String?) -> URL? {
        guard let urlString = urlString else {
            return nil
        }

        return URL(string: urlString) // may return nil if invalid urlString
    }
}


extension ImageIdentifier {
    public override var debugDescription: String {
        return "\(identifyingData)"
    }
}

extension ImageIdentifier.IdentifyingData: CustomStringConvertible {
    var description: String {
        switch self {
        case .imageUrl(let url):
            return "url: \(url)"
        case .localIdentifier(let localIdentifier):
            return "localId: \(localIdentifier)"
        case .localIdentifierAndUrl(let localIdentifier, let url):
            return "localId: \(localIdentifier), url: \(url)"
        }
    }
}
