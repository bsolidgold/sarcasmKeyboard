import UIKit
import ImageIO
import UniformTypeIdentifiers

enum GifRenderer {
    static let gifSize = CGSize(width: 320, height: 160)

    // Renders a GIF from a bundled asset if present; otherwise generates one on the fly.
    static func render(phrase: GifPhrase) -> Data? {
        if let bundled = loadBundled(phrase: phrase) { return bundled }
        return generate(phrase: phrase)
    }

    // MARK: - Bundled asset lookup

    private static func loadBundled(phrase: GifPhrase) -> Data? {
        guard let filename = phrase.gifFilename else { return nil }
        let name = (filename as NSString).deletingPathExtension
        let ext  = (filename as NSString).pathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: ext,
                                        subdirectory: "Gifs") else { return nil }
        return try? Data(contentsOf: url)
    }

    // MARK: - Programmatic generation (text-animation fallback)

    static func generate(phrase: GifPhrase) -> Data? {
        let frameCount = 8
        let frameDelay = 0.18

        let frames = (0..<frameCount).compactMap { offset in
            drawFrame(text: phrase.displayText, offset: offset)
        }
        guard frames.count == frameCount else { return nil }
        return encodeGif(frames: frames, delayTime: frameDelay)
    }

    private static func drawFrame(text: String, offset: Int) -> CGImage? {
        let renderer = UIGraphicsImageRenderer(size: gifSize)
        let img = renderer.image { _ in
            // Background
            UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: gifSize),
                         cornerRadius: 20).fill()

            let accent = UIColor(red: 0.71, green: 0.94, blue: 0.31, alpha: 1) // #B5F050
            let pale   = UIColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 1) // #E8E8E8

            let fontSize: CGFloat = text.count <= 6 ? 44 : text.count <= 10 ? 36 : text.count <= 14 ? 28 : 22
            let font = UIFont.systemFont(ofSize: fontSize, weight: .heavy)

            let attrStr = NSMutableAttributedString()
            for (i, ch) in text.enumerated() {
                let color: UIColor = (i + offset) % 2 == 0 ? accent : pale
                attrStr.append(NSAttributedString(
                    string: String(ch),
                    attributes: [.font: font, .foregroundColor: color]
                ))
            }

            let textSize = attrStr.size()
            let origin = CGPoint(
                x: (gifSize.width - textSize.width) / 2,
                y: (gifSize.height - textSize.height) / 2
            )
            attrStr.draw(at: origin)
        }
        return img.cgImage
    }

    private static func encodeGif(frames: [CGImage], delayTime: Double) -> Data? {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            data,
            UTType.gif.identifier as CFString,
            frames.count,
            nil
        ) else { return nil }

        CGImageDestinationSetProperties(dest, [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]
        ] as CFDictionary)

        for frame in frames {
            CGImageDestinationAddImage(dest, frame, [
                kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delayTime]
            ] as CFDictionary)
        }

        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }
}
