import SwiftUI
#if canImport(UIKit)
import UIKit
import CoreImage.CIFilterBuiltins

/// QR generation for circle invitations — scanned with the normal iPhone camera.
enum QRCode {
    static func image(from string: String, scale: CGFloat = 12) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
#endif
