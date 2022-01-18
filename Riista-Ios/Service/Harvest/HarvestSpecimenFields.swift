import Foundation


@objc class HarvestSpecimenFields: NSObject {
    private(set) var fields: Array<HarvestSpecimenFieldType>

    override init() {
        self.fields = Array<HarvestSpecimenFieldType>()
    }

    @objc func contains(_ field: HarvestSpecimenFieldType) -> Bool {
        return fields.contains(field)
    }

    @discardableResult
    func addField(_ field: HarvestSpecimenFieldType) -> HarvestSpecimenFields {
        fields.append(field)
        return self
    }

    @discardableResult
    func addFields(_ fields: [HarvestSpecimenFieldType]) -> HarvestSpecimenFields {
        self.fields.append(contentsOf: fields)
        return self
    }
}
