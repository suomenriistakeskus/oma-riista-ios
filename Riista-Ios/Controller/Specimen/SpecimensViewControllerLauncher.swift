import Foundation
import RiistaCommon

class SpecimensViewControllerLauncher {
    private static let logger = AppLogger(for: SpecimensViewControllerLauncher.self, printTimeStamps: false)

    class func launch<FieldId : DataFieldId>(
        parent: UIViewController?,
        fieldId: FieldId,
        specimenData: SpecimenFieldDataContainer,
        allowEdit: Bool,
        onSpecimensEditDone: OnSpecimensEditDone<FieldId>?
    ) {
        guard let parent = parent else {
            logger.w {
                "Cannot launch specimen view/edit. No parent view controller."
            }
            return
        }

        let specimensViewController: UIViewController
        if (allowEdit) {
            if (onSpecimensEditDone == nil) {
                logger.w {
                    "Launching specimen edit but there's no callback for handling results!"
                }
            }

            specimensViewController = createEditSpecimensViewController(
                fieldId: fieldId,
                specimenData: specimenData,
                onSpecimensEditDone: onSpecimensEditDone
            )
        } else {
            specimensViewController = createViewSpecimensViewController(specimenData: specimenData)
        }

        parent.navigationController?.pushViewController(specimensViewController, animated: true)
    }

    private class func createViewSpecimensViewController(
        specimenData: SpecimenFieldDataContainer
    ) -> ViewSpecimensViewController {
        return ViewSpecimensViewController(specimenData: specimenData)
    }

    private class func createEditSpecimensViewController<FieldId : DataFieldId>(
        fieldId: FieldId,
        specimenData: SpecimenFieldDataContainer,
        onSpecimensEditDone: OnSpecimensEditDone<FieldId>?
    ) -> EditSpecimensViewController<FieldId> {
        let viewController = EditSpecimensViewController(fieldId: fieldId, specimenData: specimenData)
        viewController.onSpecimensEditDone = onSpecimensEditDone
        return viewController
    }
}
