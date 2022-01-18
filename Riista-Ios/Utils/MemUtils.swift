import Foundation

class MemUtils {
    static let bytesInMegaByte: UInt = 1024 * 1024

    class func bytesToMegaBytes(bytes: UInt) -> Float {
        return Float(bytes) / Float(bytesInMegaByte)
    }

    class func megaBytesToBytes(megaBytes: UInt) -> UInt {
        return megaBytes * bytesInMegaByte
    }
}

extension UInt {

    /**
     * Treat this UInt value as a number of bytes and convert it to MB
     */
    func fromBytesToMegaBytes() -> Float {
        return MemUtils.bytesToMegaBytes(bytes: self)
    }
}
