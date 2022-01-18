import Foundation

@objc
class HarvestContext: NSObject {
    let speciesId: Int
    let gender: Gender
    let age: GameAge
    let harvestPointOfTime: Date
    let antlersLost: Bool

    var antlersPresent: Bool {
        get {
            return !antlersLost
        }
    }
    init(speciesId: Int, harvestPointOfTime: Date, gender: Gender, age: GameAge, antlersLost: Bool) {
        self.speciesId = speciesId
        self.harvestPointOfTime = harvestPointOfTime
        self.gender = gender
        self.age = age
        self.antlersLost = antlersLost
    }
}


extension HarvestContext {
    @objc class func create(speciesId: Int, harvestPointOfTime: Date?, specimen: RiistaSpecimen) -> HarvestContext {
        let gender = GenderHelper.parse(genderString: specimen.gender, fallback: .unknown)
        let age = GameAgeHelper.parse(gameAgeString: specimen.age, fallback: .unknown)
        let harvestPointOfTime = harvestPointOfTime ?? Date()
        let antlersLost = specimen.antlersLost?.boolValue ?? false

        return HarvestContext(speciesId: speciesId, harvestPointOfTime: harvestPointOfTime,
                              gender: gender, age: age, antlersLost: antlersLost)
    }
}

extension HarvestContext {
    @objc func isSpecies(speciesId: Int) -> Bool {
        return isSpecies(speciesIds: [speciesId])
    }

    @objc func isSpecies(speciesIds: [Int]) -> Bool {
        return speciesIds.contains(self.speciesId)
    }

    @objc func isYoung() -> Bool {
        return age == .young
    }

    @objc func isAdultMale() -> Bool {
        return age == .adult && gender == .male
    }

    func isMoose() -> Bool {
        return SpeciesUtils.isMoose(speciesCode: speciesId)
    }

    func isDeer() -> Bool {
        return SpeciesUtils.isDeer(speciesCode: speciesId)
    }
}
