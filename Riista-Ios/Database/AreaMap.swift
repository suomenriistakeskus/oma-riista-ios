import Foundation

@objc class AreaMap : NSObject, NSCoding, Codable {
    var number : Int?
    var name : String?

    enum CodingKeys: String, CodingKey {
        case number = "number"
        case name = "name"
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        number = try values.decodeIfPresent(Int.self, forKey: .number)
        name = try values.decodeIfPresent(String.self, forKey: .name)
    }

    required init?(coder decoder: NSCoder) {
        self.number = decoder.decodeInteger(forKey: "number")
        self.name = decoder.decodeObject(forKey: "name") as? String
    }

    func encode(with coder: NSCoder) {
        coder.encode(number!, forKey: "number")
        coder.encode(name!, forKey: "name")
    }

    @objc func getAreaNumberAsString() -> String {
        return String(number!)
    }

    @objc func getAreaName() -> String? {
        return name
    }
}
