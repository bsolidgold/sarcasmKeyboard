import SwiftUI
import SarcasmKit

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ProStore.self) private var store
    private var accent: Color { Palette.default.accent(for: colorScheme) }

    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Keyboard", systemImage: "keyboard") }
            NavigationStack { HistoryView() }
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(accent)
        .preferredColorScheme(store.isDarkMode ? .dark : .light)
    }
}

#Preview {
    ContentView()
        .environment(ProStore())
}
