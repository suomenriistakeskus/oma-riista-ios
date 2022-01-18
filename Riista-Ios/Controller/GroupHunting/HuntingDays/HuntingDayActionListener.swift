import Foundation
import RiistaCommon

protocol HuntingDayActionListener: AnyObject {
    func onViewHuntingDay(viewModel: HuntingDayViewModel)
    func onEditHuntingDay(huntingDayId: GroupHuntingDayId)
    func onCreateHuntingDay(preferredDate: RiistaCommon.LocalDate?)

    /**
     * Notifies the listener that the hunting days have been updated and listener should update
     * its own data structures as well.
     */
    func onHuntingDaysChanged()
}
