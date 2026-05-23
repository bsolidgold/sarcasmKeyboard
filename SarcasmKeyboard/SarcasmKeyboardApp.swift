import SwiftUI
import SarcasmKit

@main
struct SarcasmKeyboardApp: App {
    @State private var proStore = ProStore()

    init() {
        #if DEBUG
        seedHistoryIfEmpty()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(proStore)
                .task { await proStore.bootstrap() }
        }
    }
}

#if DEBUG
private func seedHistoryIfEmpty() {
    guard HistoryStore.load().isEmpty else { return }
    let samples: [(String, String)] = [
        ("oH yOu'Re SoRrY? hOw OrIgInAl", "alternating"),
        ("sUrE, i'Ll GeT rIgHt On ThAt", "alternating"),
        ("wOw ThAnKs FoR tHaT uNsOlIcItEd OpInIoN", "alternating"),
        ("yEaH nO i ToTaLlY bElIeVe YoU", "alternating"),
        ("aS iF i WaSnT aLrEaDy AwArE", "alternating"),
        ("tHaNkS i HaD nO iDeA", "alternating"),
        ("oH wOw WhAt A gReAt IdEa YoU hAvE", "alternating"),
        ("sO hApPy FoR yOu RiGhT nOw", "alternating"),
        ("tHaT's ReAlLy CoOl AnD i CaRe So MuCh", "alternating"),
        ("mUsT bE nIcE tO bE sO aMaZiNg", "alternating"),
    ]
    samples.forEach { HistoryStore.append(HistoryEntry(output: $0.0, patternID: $0.1)) }
}
#endif
