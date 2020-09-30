import Foundation

class MapAreaManager: NSObject {

    class func fetchMooseAreaMaps(completion: @escaping RiistaJsonArrayCompletion) {
        let network = RiistaNetworkManager.sharedInstance()
        network?.listMooseAreaMaps(completion)
    }

    class func fetchPienriistaAreaMaps(completion: @escaping RiistaJsonArrayCompletion) {
        let network = RiistaNetworkManager.sharedInstance()
        network?.listPienriistaAreaMaps(completion)
    }
}
