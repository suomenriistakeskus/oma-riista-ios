extension UIImage {
    @objc func aspectFit(toSize newSize: CGSize) -> UIImage? {
        let aspectRatio = size.aspectRatio()
        let targetAspectRatio = newSize.aspectRatio()

        let drawSize: CGSize;

        if (targetAspectRatio > aspectRatio) {
            // target is wider than current -> match heights
            drawSize = CGSize(width: newSize.height * aspectRatio, height: newSize.height)
        } else {
            // target is taller -> match widths
            drawSize = CGSize(width: newSize.width, height: newSize.width / aspectRatio)
        }

        let newImage: UIImage?
        let clipRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral

        // center the image in the clip rect
        let drawRect = CGRect(x: (newSize.width - drawSize.width) / 2,
                              y: (newSize.height - drawSize.height) / 2,
                              width: drawSize.width,
                              height: drawSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.interpolationQuality = .high
        context.clip(to: clipRect)
        draw(in: drawRect)
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}


