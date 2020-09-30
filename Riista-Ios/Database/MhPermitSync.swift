import Foundation

@objc
class MhPermitSync: NSObject {

    @objc
    static let shared = MhPermitSync()

    override private init() {
    }

    @objc
    static func anyPermitsExist() -> Bool {
        let delegate = UIApplication.shared.delegate as! RiistaAppDelegate
        let context = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        context.parent = delegate.managedObjectContext

        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MhPermit")

        do {
            let count = try context.count(for: fetch)
            return count > 0
        } catch _ as NSError {
            return false
        }
    }

    @objc
    func sync(completion: @escaping RiistaJsonArrayCompletion) -> Void {
        let delegate = UIApplication.shared.delegate as! RiistaAppDelegate
        let context = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        context.parent = delegate.managedObjectContext

        RiistaNetworkManager.sharedInstance()?.listMhPermits() { (items, error) in
            if (error == nil) {
                let deleteError = self.deleteAllExisting(delegate: delegate, context: context)
                if let deleteError = deleteError {
                    completion(nil, deleteError)
                    return
                }

                for item in items! {
                    let permit = MhPermitSync.mhPermitFromDict(dict: item as! NSDictionary, objectContext: context)
                    context.insert(permit)
                }

                RiistaModelUtils.saveContexts(context)
            }

            if error != nil {
                completion(nil, error)
            }
            else {
                completion(items, nil)
            }
        }
    }

    func deleteAllExisting(delegate:RiistaAppDelegate, context:NSManagedObjectContext) -> Error? {
        if #available(iOS 9.0, *) {
            do {
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MhPermit")
                let request = NSBatchDeleteRequest(fetchRequest: fetch)
                try context.execute(request)
            } catch {
                return error
            }
            return nil
        } else {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MhPermit")
            fetch.returnsObjectsAsFaults = false
            do {
                let results = try context.fetch(fetch)
                for managedObject in results
                {
                    if let managedObbjectData:NSManagedObject = managedObject as? NSManagedObject {
                        context.delete(managedObbjectData)
                    }
                }
            } catch {
                return error
            }
            return nil
        }
    }

    class func mhPermitFromDict(dict:NSDictionary, objectContext:NSManagedObjectContext) -> MhPermit {
        let entity = NSEntityDescription.entity(forEntityName: "MhPermit", in: objectContext)!
        let permit = MhPermit.init(entity: entity, insertInto: objectContext)

        permit.permitIdentifier = dict["permitIdentifier"] as! String
        permit.permitType = dict["permitType"] as! NSDictionary?
        permit.permitName = dict["permitName"] as! NSDictionary?
        permit.areaNumber = dict["areaNumber"] as! String
        permit.areaName = dict["areaName"] as! NSDictionary?

        permit.beginDate = (RiistaModelUtils.checkNull((dict as! [AnyHashable : Any]), key: "beginDate") as! String?)
        permit.endDate = (RiistaModelUtils.checkNull((dict as! [AnyHashable : Any]), key: "endDate") as! String?)

        permit.harvestFeedbackUrl = dict["harvestFeedbackUrl"] as! NSDictionary?

        return permit
    }

    class func dictFromMhPermit(permit:MhPermit) -> NSDictionary? {
        let exception = NSException(name: NSExceptionName.genericException, reason: "Not implemented", userInfo: nil)
        exception.raise()

        return nil
    }
}
