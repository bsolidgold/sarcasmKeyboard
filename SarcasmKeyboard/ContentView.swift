import SwiftUI
import SarcasmKit

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
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
    }
}

#Preview {
    ContentView()
        .environment(ProStore())
}
