/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

#if os(iOS)
import UIKit

private var redactedImageKey: UInt8 = 0

extension UIImage {
    var redactionColor: UIColor {
        dominantColor ?? .black
    }

    func redactingText() throws -> UIImage {
        if let redactedImage = objc_getAssociatedObject(self, &redactedImageKey) {
            return redactedImage as? UIImage ?? self
        }

        let rectangles = try textRectangles()

        guard !rectangles.isEmpty else {
            objc_setAssociatedObject(self, &redactedImageKey, NSNull(), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return self
        }

        let redactedImage = image(redactingRectangles: rectangles)
        objc_setAssociatedObject(self, &redactedImageKey, redactedImage, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        return redactedImage
    }

    func image(redactingRectangles rects: [CGRect], color: UIColor? = nil) -> UIImage {
        guard !rects.isEmpty else {
            return self
        }

        return UIGraphicsImageRenderer(size: size, format: imageRendererFormat).image { context in
            draw(at: .zero)
            (color ?? redactionColor).setFill()
            rects
                .map { $0.intersection(CGRect(origin: .zero, size: size)) }
                .filter { !$0.isNull }
                .forEach(UIRectFill)
        }
    }
}
#endif
