import SwiftUI
import UIKit

/// An immutable, validated payload for the system share sheet.
///
/// Keeping presentation and its items in one value avoids presenting a sheet in
/// the render pass before a separately stored optional image is available.
struct SharePayload: Identifiable {
    let id = UUID()
    let activityItems: [Any]

    init(image: UIImage?, fallbackText: String) {
        if let image, image.size.width > 0, image.size.height > 0,
           image.cgImage != nil || image.ciImage != nil {
            activityItems = [image]
        } else {
            let text = fallbackText.trimmingCharacters(in: .whitespacesAndNewlines)
            activityItems = [text.isEmpty ? "Shared from Steadfast" : text]
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let payload: SharePayload

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: payload.activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
