import Messages
import SwiftUI
import UIKit

final class MessagesViewController: MSMessagesAppViewController {
    private var hostingController: UIHostingController<GifPickerView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1)

        let picker = GifPickerView { [weak self] phrase in
            self?.insertGif(phrase)
        }
        let host = UIHostingController(rootView: picker)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        addChild(host)
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
        hostingController = host
    }

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        requestPresentationStyle(.expanded)
    }

    // MARK: - GIF insertion

    private func insertGif(_ phrase: GifPhrase) {
        guard let conversation = activeConversation,
              let gifData = GifRenderer.render(phrase: phrase) else { return }

        // Copy to clipboard so it can be pasted in other apps
        UIPasteboard.general.setData(gifData, forPasteboardType: "com.compuserve.gif")

        // Write to temp file; Messages needs a file URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(phrase.id)
            .appendingPathExtension("gif")

        do {
            try gifData.write(to: tempURL, options: .atomic)
            conversation.insertAttachment(tempURL, withAlternateFilename: "\(phrase.displayText).gif") { [weak self] error in
                try? FileManager.default.removeItem(at: tempURL)
                if error != nil {
                    // Attachment failed — clipboard copy already succeeded so user can paste
                    self?.requestPresentationStyle(.compact)
                }
            }
        } catch {
            // Couldn't write temp file; clipboard copy is the fallback
        }
    }
}
