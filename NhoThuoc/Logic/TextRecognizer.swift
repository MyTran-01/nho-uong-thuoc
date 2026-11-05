import Foundation
import CoreGraphics
import Vision

/// On-device text recognition (Apple Vision). No network, no cost.
nonisolated enum TextRecognizer {
    /// Returns printed lines, top to bottom. `cgImage` must already be upright.
    static func lines(in cgImage: CGImage) async throws -> [String] {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = [Locale.Language(identifier: "vi-VN")]
        let observations = try await request.perform(on: cgImage)
        let fragments = observations.compactMap { obs -> RxParser.Fragment? in
            guard let text = obs.topCandidates(1).first?.string else { return nil }
            let box = obs.boundingBox // normalised, origin bottom-left
            return RxParser.Fragment(text: text,
                                     midY: 1 - (box.origin.y + box.height / 2),
                                     minX: box.origin.x,
                                     height: box.height)
        }
        return RxParser.lines(from: fragments)
    }
}
