import UIKit
import SwiftUI
import SarcasmKit

final class KeyboardViewController: UIInputViewController {
    private var hostingController: UIHostingController<KeyboardView>?
    private var historySession: HistorySession?

    override func viewDidLoad() {
        super.viewDidLoad()
        KeyboardStatus.recordHeartbeat()
        historySession = HistorySession(write: HistoryStore.append)

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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        flushHistory()
    }

    private func makeKeyboardView() -> KeyboardView {
        KeyboardView(
            onLetter:       { [weak self] char in self?.handleLetter(char) },
            onPunctuation:  { [weak self] char in self?.handlePunctuation(char) },
            onSpace:        { [weak self] in self?.handleLetter(" ") },
            onDelete:       { [weak self] in self?.handleDelete() },
            onReturn:       { [weak self] in self?.handleReturn() },
            onCyclePattern: { [weak self] in self?.cyclePattern() },
            currentPattern: Self.resolvedPattern(),
            palette:        Self.resolvedTheme().palette
        )
    }

    // If the user lost Pro (refund, family-sharing revoke) while a premium
    // pattern/theme is still selected in SharedDefaults, fall back to a free
    // default so the keyboard keeps working.
    private static func resolvedPattern() -> any SarcasmPattern {
        let p = SharedDefaults.selectedPattern
        if p.isPremium && !SharedDefaults.isPro {
            return AlternatingPattern()
        }
        return p
    }

    private static func resolvedTheme() -> Theme {
        let t = SharedDefaults.selectedTheme
        if t.isPremium && !SharedDefaults.isPro {
            return ThemeCatalog.acid
        }
        return t
    }

    private func handleLetter(_ char: Character) {
        let prior   = textDocumentProxy.documentContextBeforeInput ?? ""
        let pattern = SharedDefaults.selectedPattern
        let out     = pattern.transformCharacter(char, priorContext: prior)
        textDocumentProxy.insertText(out)
        historySession?.append(out)
    }

    private func handlePunctuation(_ char: Character) {
        let s = String(char)
        textDocumentProxy.insertText(s)
        historySession?.append(s)
    }

    private func handleDelete() {
        textDocumentProxy.deleteBackward()
        historySession?.removeLast()
    }

    private func handleReturn() {
        textDocumentProxy.insertText("\n")
        flushHistory()
    }

    private func flushHistory() {
        historySession?.flush(currentPatternID: SharedDefaults.selectedPatternID)
    }

    private func cyclePattern() {
        let nextID = PatternCycler.next(
            currentID: SharedDefaults.selectedPatternID,
            in: SarcasmEngine.allPatterns,
            includePremium: SharedDefaults.isPro
        )
        SharedDefaults.selectedPatternID = nextID
        hostingController?.rootView = makeKeyboardView()
    }
}
