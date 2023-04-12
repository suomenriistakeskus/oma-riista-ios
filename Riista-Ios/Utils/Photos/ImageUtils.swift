import Foundation
import RiistaCommon

typealias ImageLoadSucceeded = (UIImage) -> Void
typealias ImageLoadFailed = (PhotoAccessFailureReason) -> Void

@objc class ImageUtils: NSObject {

    private static let commonImageManager = CommonImageManager()


    @objc class func selectDisplayedImage(_ entryImages: Array<DiaryImage>?) -> DiaryImage? {
        return entryImages?.first(where: { (image: DiaryImage) -> Bool in
            guard let imageStatus = image.status else {
                // nil status is acceptable (it shouldn't happen but for some reason
                // we keep seeing this)
                return true
            }

            return imageStatus.intValue != DiaryImageStatusDeletion
        })
    }

    @objc class func loadEventImage(_ entry: DiaryEntryBase?,
                                    for imageView: UIImageView,
                                    options: ImageLoadOptions,
                                    onSuccess: @escaping ImageLoadSucceeded,
                                    onFailure: @escaping ImageLoadFailed) {
        guard let entry = entry else {
            print("cannot load image for <nil> entry")
            onFailure(.unspecified)
            return
        }

        let images: Array<DiaryImage>?
        let speciesCode: Int?

        switch entry {
        case let observation as ObservationEntry:
            images = observation.diaryImages?.map({ $0 as! DiaryImage })
            speciesCode = observation.gameSpeciesCode?.intValue
            break
        case let srva as SrvaEntry:
            images = srva.diaryImages?.map({ $0 as! DiaryImage })
            speciesCode = srva.gameSpeciesCode?.intValue
            break
        case let harvest as DiaryEntry:
            images = harvest.diaryImages?.map({ $0 as! DiaryImage })
            speciesCode = harvest.gameSpeciesCode?.intValue
            break
        default:
            print("unknown event type when loading event image");
            onFailure(.unspecified)
            return
        }

        if let eventImage = ImageUtils.selectDisplayedImage(images) {
            loadDiaryImage(eventImage, imageView: imageView, options: options, onSuccess: onSuccess, onFailure: onFailure)
        } else {
            loadSpeciesImage(speciesCode: speciesCode ?? 0, onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    @objc class func loadDiaryImage(_ image: DiaryImage,
                                    imageView: UIImageView,
                                    options: ImageLoadOptions,
                                    onSuccess: @escaping ImageLoadSucceeded,
                                    onFailure: @escaping ImageLoadFailed) {
        let loadIndicator: UIActivityIndicatorView?
        if (image.type.intValue == DiaryImageTypeRemote) {
            // only indicate loading from network
            loadIndicator = UIActivityIndicatorView(style: .gray)
            loadIndicator?.frame = imageView.bounds
            imageView.addSubview(loadIndicator!)
            loadIndicator?.startAnimating()
        } else {
            loadIndicator = nil
        }

        let stopLoadIndication = { [weak loadIndicator] in
            guard let loadIndicator = loadIndicator else { return }

            loadIndicator.stopAnimating()
            loadIndicator.removeFromSuperview()
        }

        ImageUtils.loadDiaryImage(
            image,
            options: options,
            onSuccess: { image in
                stopLoadIndication()
                onSuccess(image)
            },
            onFailure: { failureReason in
                stopLoadIndication()
                onFailure(failureReason)
            })
    }

    @objc class func loadDiaryImage(_ image: DiaryImage,
                                    options: ImageLoadOptions,
                                    onSuccess: @escaping ImageLoadSucceeded,
                                    onFailure: @escaping ImageLoadFailed) {
        if (image.type.intValue == DiaryImageTypeLocal) {
            guard let loadRequest = ImageLoadRequest.from(diaryImage: image, options: options) else {
                onFailure(.unspecified)
                return
            }

            LocalImageManager.instance.loadImage(loadRequest) { result in
                switch result {
                case .success(let identifiableImage):
                    onSuccess(identifiableImage.image)
                    break
                case .failure(let reason, _):
                    onFailure(reason)
                    break
                }
            }
        } else {
            RiistaNetworkManager.sharedInstance()?.loadDiaryEntryImage(
                image.imageid,
                completion: { (image: UIImage?, error: Error?) in
                    if let image = image {
                        let resultImage = options.applyTransformations(for: image)
                        onSuccess(resultImage)
                    } else {
                        onFailure(.unspecified)
                    }
            })
        }
    }

    // MARK: EntityImage support

    class func loadEntityImageOrSpecies(
        image: EntityImage?,
        speciesCode: Int?,
        imageView: UIImageView,
        options: ImageLoadOptions,
        onSuccess: @escaping ImageLoadSucceeded,
        onFailure: @escaping ImageLoadFailed
    ) {
        if let image = image {
            loadEntityImage(image: image, imageView: imageView, options: options, onSuccess: onSuccess, onFailure: onFailure)
        } else {
            loadSpeciesImage(speciesCode: speciesCode ?? 0, onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    class func loadEntityImage(
        image: EntityImage,
        imageView: UIImageView,
        options: ImageLoadOptions,
        onSuccess: @escaping ImageLoadSucceeded,
        onFailure: @escaping ImageLoadFailed
    ) {
        let loadIndicator: UIActivityIndicatorView?
        if (image.status == .uploaded) {
            // only indicate loading from network
            loadIndicator = UIActivityIndicatorView(style: .gray)
            loadIndicator?.frame = imageView.bounds
            imageView.addSubview(loadIndicator!)
            loadIndicator?.startAnimating()
        } else {
            loadIndicator = nil
        }

        let stopLoadIndication = { [weak loadIndicator] in
            guard let loadIndicator = loadIndicator else { return }

            loadIndicator.stopAnimating()
            loadIndicator.removeFromSuperview()
        }

        ImageUtils.loadEntityImage(
            image: image,
            options: options,
            onSuccess: { image in
                stopLoadIndication()
                onSuccess(image)
            },
            onFailure: { failureReason in
                stopLoadIndication()
                onFailure(failureReason)
            })
    }

    class func loadEntityImage(
        image: EntityImage,
        options: ImageLoadOptions,
        onSuccess: @escaping ImageLoadSucceeded,
        onFailure: @escaping ImageLoadFailed
    ) {
        if (image.status == .local || image.status == .uploaded) {
            loadLocalEntityImage(
                image: image,
                options: options,
                onSuccess: onSuccess,
                onFailure: { _ in
                    // fallback to remote image loading
                    loadRemoteEntityImage(image: image, options: options, onSuccess: onSuccess, onFailure: onFailure)
                }
            )
        } else {
            loadRemoteEntityImage(image: image, options: options, onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    private class func loadLocalEntityImage(
        image: EntityImage,
        options: ImageLoadOptions,
        onSuccess: @escaping ImageLoadSucceeded,
        onFailure: @escaping ImageLoadFailed
    ) {
        var startedLoadingFromCommonLib: Bool = false

        // prefer gallery over directories managed by common lib
        loadLocalEntityImageFromGallery(
            image: image,
            options: options,
            onSuccess: onSuccess
        ) { _ in
            // it is possible that we receive multiple failure callbacks
            if (startedLoadingFromCommonLib) {
                // no need to start again
                return
            }
            startedLoadingFromCommonLib = true

            print("Loading from gallery failed!")
            // image not available from gallery, attempt to load it from common lib
            loadLocalEntityImageFromCommonLib(
                image: image,
                options: options,
                onSuccess: onSuccess,
                onFailure: onFailure
            )
        }
    }

    private class func loadLocalEntityImageFromGallery(
        image: EntityImage,
        options: ImageLoadOptions,
        onSuccess: @escaping ImageLoadSucceeded,
        onFailure: @escaping ImageLoadFailed
    ) {
        guard let loadRequest = ImageLoadRequest.from(entityImage: image, options: options) else {
            onFailure(.unspecified)
            return
        }

        LocalImageManager.instance.loadImage(loadRequest) { result in
            switch result {
            case .success(let identifiableImage):
                onSuccess(identifiableImage.image)
                break
            case .failure(let reason, _):
                onFailure(reason)
                break
            }
        }
    }

    private class func loadLocalEntityImageFromCommonLib(
        image: EntityImage,
        options: ImageLoadOptions,
        onSuccess: @escaping ImageLoadSucceeded,
        onFailure: @escaping ImageLoadFailed
    ) {
        guard let imageFileUuid = image.serverId else {
            onFailure(.unspecified)
            return
        }

        commonImageManager.loadImage(imageFileUuid: imageFileUuid) { image in
            guard let image = image else {
                onFailure(.unspecified)
                return
            }

            let resultImage = options.applyTransformations(for: image)
            onSuccess(resultImage)
        }
    }

    private class func loadRemoteEntityImage(
        image: EntityImage,
        options: ImageLoadOptions,
        onSuccess: @escaping ImageLoadSucceeded,
        onFailure: @escaping ImageLoadFailed
    ) {
        guard let serverId = image.serverId else {
            onFailure(.unspecified)
            return
        }

        RiistaNetworkManager.sharedInstance()?.loadDiaryEntryImage(
            serverId,
            completion: { (image: UIImage?, error: Error?) in
                if let image = image {
                    let resultImage = options.applyTransformations(for: image)
                    onSuccess(resultImage)
                } else {
                    onFailure(.unspecified)
                }
            }
        )
    }

    @objc class func loadSpeciesImage(speciesCode: Int, onSuccess: ImageLoadSucceeded, onFailure: ImageLoadFailed) {
        let image: UIImage?
        if (speciesCode == 0) {
            // SRVA other species
            image = UIImage.init(named: "unknown_white")?.withRenderingMode(.alwaysTemplate)
        } else {
            image = loadSpeciesImage(speciesCode: speciesCode)
        }

        if let image = image {
            onSuccess(image)
        } else {
            onFailure(.unspecified)
        }
    }

    @objc class func loadSpeciesImage(speciesCode: Int) -> UIImage? {
        let imageName = String(format: "species_%d.jpg", arguments: [speciesCode])
        if let speciesImage = UIImage.init(named: imageName) {
            return speciesImage
        } else {
            return UIImage(named: "ic_launcher.png")
        }
    }

    @objc class func loadSpeciesImage(speciesCode: Int, size: CGSize) -> UIImage? {
        return loadSpeciesImage(speciesCode: speciesCode)?.resizedImageToFit(in: size, scaleIfSmaller: false)
    }
}
