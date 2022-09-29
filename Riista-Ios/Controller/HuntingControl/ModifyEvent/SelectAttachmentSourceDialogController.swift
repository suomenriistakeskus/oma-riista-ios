import Foundation

typealias OnAttachmentSourceSelected = (_ source: SelectAttachmentSourceDialogController.AttachmentSource) -> Void

class SelectAttachmentSourceDialogController: MaterialDialogViewController {

    enum AttachmentSource: CaseIterable {
        case takePhoto, pickFromPhotos, pickFile
    }

    var allowedAttachmentSources: [AttachmentSource] = AttachmentSource.allCases

    var listener: OnAttachmentSourceSelected?

    override func loadView() {
        super.loadView()

        buttonArea.isHidden = true
        titleLabel.text = "HuntingControlAddAttachment".localized()

        let sourcesStackView = UIStackView()
        sourcesStackView.axis = .vertical
        sourcesStackView.alignment = .fill
        contentViewContainer.addSubview(sourcesStackView)
        sourcesStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        allowedAttachmentSources.forEach { source in
            sourcesStackView.addArrangedSubview(createButtonForAttachmentSource(source: source))
        }
    }

    private func createButtonForAttachmentSource(source: AttachmentSource) -> MaterialButton {
        let button = MaterialButton()
        button.applyTextTheme(withScheme: AppTheme.shared.textButtonScheme())
        button.setTitle(source.localizedActionName, for: .normal)
        button.contentHorizontalAlignment = .left
        button.onClicked = { [weak self] in
            guard let listener = self?.listener else {
                print("Could not obtain delegate, cannot inform about source selection")
                return
            }
            self?.dismiss(animated: true)
            listener(source)
        }


        button.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.UI.ButtonHeightSmall)
        }

        return button
    }
}

fileprivate extension SelectAttachmentSourceDialogController.AttachmentSource {
    var localizedActionName: String {
        switch self {
        case .takePhoto:   return "HuntingControlAttachmentTakePhoto".localized()
        case .pickFromPhotos:   return "HuntingControlAttachmentPickFromPhotos".localized()
        case .pickFile:     return "HuntingControlAttachmentPickFile".localized()
        }
    }
}
