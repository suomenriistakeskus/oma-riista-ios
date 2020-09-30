import Foundation
import CoreData


extension MhPermit {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MhPermit> {
        return NSFetchRequest<MhPermit>(entityName: "MhPermit")
    }

    @NSManaged public var areaName: NSDictionary?
    @NSManaged public var areaNumber: String
    @NSManaged public var beginDate: String?
    @NSManaged public var endDate: String?
    @NSManaged public var permitIdentifier: String
    @NSManaged public var permitName: NSDictionary?
    @NSManaged public var permitType: NSDictionary?
    @NSManaged public var harvestFeedbackUrl: NSDictionary?

}
