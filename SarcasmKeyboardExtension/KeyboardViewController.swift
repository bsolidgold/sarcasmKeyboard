import UIKit
import SwiftUI
import SarcasmKit

final class KeyboardViewController: UIInputViewController {
    private var hostingController: UIHostingController<KeyboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        KeyboardStatus.recordHeartbeat()

        let host = UIHostingController(rootView: makeKeyboardView())
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        addChild(host)
        self.view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        hostingController = host
    }

    private func makeKeyboardView() -> KeyboardView {
        KeyboardView(
            onLetter:       { [weak self] char in self?.handleLetter(char) },
            onPunctuation:  { [weak self] char in self?.handlePunctuation(char) },
            onSpace:        { [weak self] in self?.handleLetter(" ") },
            onDelete:       { [weak self] in self?.textDocumentProxy.deleteBackward() },
            onReturn:       { [weak self] in self?.textDocumentProxy.insertText("\n") },
            onGlobe:        { [weak self] in self?.advanceToNextInputMode() },
            onCyclePattern: { [weak self] in self?.cyclePattern() },
            currentPattern: SharedDefaults.selectedPattern,
            palette:        SharedDefaults.selectedTheme.palette
        )
    }

    private func handleLetter(_ char: Character) {
        let prior   = textDocumentProxy.documentContextBeforeInput ?? ""
        let pattern = SharedDefaults.selectedPattern
        let out     = pattern.transformCharacter(char, priorContext: prior)
        textDocumentProxy.insertText(out)
    }

    private func handlePunctuation(_ char: Character) {
        textDocumentProxy.insertText(String(char))
    }

    private func cyclePattern() {
        let nextID = PatternCycler.next(
            currentID: SharedDefaults.selectedPatternID,
            in: SarcasmEngine.allPatterns
        )
        SharedDefaults.selectedPatternID = nextID
        hostingController?.rootView = makeKeyboardView()
    }
}
