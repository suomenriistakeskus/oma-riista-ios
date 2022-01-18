import Foundation


protocol PropertyStoring {
    associatedtype T

    func getAssociatedObject(_ key: UnsafeRawPointer!, defaultValue: T) -> T
    func setAssociatedObject(_ key: UnsafeRawPointer!, value: T)
    func withAssociatedObject(_ key: UnsafeRawPointer!, defaultValue: T, updateFunc: (inout T) -> Void)
}

/*
 Implementation based on https://marcosantadev.com/stored-properties-swift-extensions/
 */
extension PropertyStoring {
    func getAssociatedObject(_ key: UnsafeRawPointer!, defaultValue: T) -> T {
        guard let value = objc_getAssociatedObject(self, key) as? T else {
            return defaultValue
        }
        return value
    }

    func setAssociatedObject(_ key: UnsafeRawPointer!, value: T) {
        objc_setAssociatedObject(self, key, value, .OBJC_ASSOCIATION_RETAIN)
    }

    func withAssociatedObject(_ key: UnsafeRawPointer!, defaultValue: T, updateFunc: (inout T) -> Void) {
        var associatedObject = getAssociatedObject(key, defaultValue: defaultValue)
        updateFunc(&associatedObject)
        setAssociatedObject(key, value: associatedObject)
    }
}
