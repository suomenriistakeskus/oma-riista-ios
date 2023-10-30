import Foundation
import RiistaCommon

protocol MetsahallitusPermitActionListener: AnyObject {
    func onViewMetsahallitusPermit(permit: CommonMetsahallitusPermit)
}
