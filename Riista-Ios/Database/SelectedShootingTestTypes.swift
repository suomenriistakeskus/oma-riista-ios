import Foundation

struct SelectedShootingTestTypes : Codable {
    let mooseTestIntended : Bool?
    let bearTestIntended : Bool?
    let roeDeerTestIntended : Bool?
    let bowTestIntended : Bool?

    enum CodingKeys: String, CodingKey {
        case mooseTestIntended = "mooseTestIntended"
        case bearTestIntended = "bearTestIntended"
        case roeDeerTestIntended = "roeDeerTestIntended"
        case bowTestIntended = "bowTestIntended"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        mooseTestIntended = try values.decodeIfPresent(Bool.self, forKey: .mooseTestIntended)
        bearTestIntended = try values.decodeIfPresent(Bool.self, forKey: .bearTestIntended)
        roeDeerTestIntended = try values.decodeIfPresent(Bool.self, forKey: .roeDeerTestIntended)
        bowTestIntended = try values.decodeIfPresent(Bool.self, forKey: .bowTestIntended)
    }

    init(mooseTestIntended: Bool, bearTestIntended: Bool, roeDeerTestIntended: Bool, bowTestIntended: Bool) {
        self.mooseTestIntended = mooseTestIntended
        self.bearTestIntended = bearTestIntended
        self.roeDeerTestIntended = roeDeerTestIntended
        self.bowTestIntended = bowTestIntended
    }
}
