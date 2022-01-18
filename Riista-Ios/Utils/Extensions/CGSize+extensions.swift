import Foundation

extension CGSize {
    func aspectRatio() -> CGFloat {
        return width / height
    }

    /**
     * Converts this CGSize to pixels (assuming this CGSize represents points)
     */
    func toPixels() -> CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: width * scale, height: height * scale)
    }


}
