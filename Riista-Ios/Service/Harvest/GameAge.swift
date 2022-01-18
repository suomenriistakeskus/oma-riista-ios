import Foundation

@objc enum GameAge: Int, CustomStringConvertible {
    case adult
    case young
    case unknown

    var description: String {
        return GameAgeHelper.stringFor(gameAge: self)!
    }
}

@objc class GameAgeHelper: NSObject {
    static let typeStrings: Dictionary<GameAge, String> = [.adult: "ADULT", .young: "YOUNG", .unknown: "UNKNOWN"]

    @objc public static func stringFor(gameAge: GameAge) -> String? {
        return GameAgeHelper.typeStrings[gameAge]
    }

    /**
     Attempts to parse the given string as GameAge. Will return given fallback  if parsing fails.
     */
    @objc public static func parse(gameAgeString: String?, fallback: GameAge) -> GameAge {
        guard let gameAgeString = gameAgeString else {
            print("GameAge parsing failed: <nil>, returning \(fallback)")
            return fallback
        }

        let gameAge = GameAgeHelper.typeStrings.first { (key: GameAge, value: String) -> Bool in
            return value == gameAgeString
        }?.key

        if let gameAge = gameAge {
            return gameAge
        }

        print("GameAge parsing failed: \(gameAgeString), returning \(fallback)")
        return fallback
    }
}
