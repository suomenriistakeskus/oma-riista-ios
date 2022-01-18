import Foundation

@objc class JSONUtils: NSObject {

    @objc class func parseString(_ jsonString: String?) -> Any? {
        guard let jsonString = jsonString else { return nil }

        if let jsonData = jsonString.data(using: .utf8) {
            do {
                let result = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions())

                return result
            } catch {
                print("Failed to parse to json")
            }
        }

        return nil
    }
}
