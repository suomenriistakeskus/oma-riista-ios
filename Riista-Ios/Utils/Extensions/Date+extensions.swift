import Foundation

extension Date {
    func getComponent(_ component: Calendar.Component, calendar: Calendar = .current) -> Int {
        return calendar.component(component, from: self)
    }
}
