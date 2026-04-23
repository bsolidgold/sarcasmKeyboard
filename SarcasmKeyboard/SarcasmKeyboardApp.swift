import SwiftUI

@main
struct SarcasmKeyboardApp: App {
    @State private var proStore = ProStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(proStore)
                .task { await proStore.bootstrap() }
        }
    }
}
