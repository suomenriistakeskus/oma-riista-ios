import Foundation

class MapAreaManager: NSObject {

    private static var cachedMooseAreaMaps: [Any]? = nil
    private static var cachedPienriistaAreaMaps: [Any]? = nil

    class func fetchMooseAreaMaps(completion: @escaping RiistaJsonArrayCompletion) {
        if let network = RiistaNetworkManager.sharedInstance() {
            network.listMooseAreaMaps { mooseMaps, error in
                if (mooseMaps != nil) {
                    cachedMooseAreaMaps = mooseMaps
                }

                notifyCompletion(
                    resultMaps: mooseMaps ?? cachedMooseAreaMaps,
                    error: error,
                    completion: completion
                )
            }
        }
    }

    class func fetchPienriistaAreaMaps(completion: @escaping RiistaJsonArrayCompletion) {
        if let network = RiistaNetworkManager.sharedInstance() {
            network.listPienriistaAreaMaps { pienriistaMaps, error in
                if (pienriistaMaps != nil) {
                    cachedPienriistaAreaMaps = pienriistaMaps
                }

                notifyCompletion(
                    resultMaps: pienriistaMaps ?? cachedPienriistaAreaMaps,
                    error: error,
                    completion: completion
                )
            }
        }
    }

    private class func notifyCompletion(
        resultMaps: [Any]?,
        error: Error?,
        completion: @escaping RiistaJsonArrayCompletion
    ) {
        var resultError = error
        if (resultMaps != nil) {
            resultError = nil
        }

        completion(resultMaps, resultError)
    }
}
