import SwiftUI
import SarcasmKit

struct GifPickerView: View {
    let onSelect: (GifPhrase) -> Void

    @State private var inserting: String? = nil
    @State private var showProBanner = false

    private var isPro: Bool { SharedDefaults.isPro }

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 0.06, green: 0.06, blue: 0.06).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(GifLibrary.all) { phrase in
                            PhraseCard(
                                phrase: phrase,
                                isLocked: !phrase.isFree && !isPro,
                                isInserting: inserting == phrase.id
                            )
                            .onTapGesture { handleTap(phrase) }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
                }
            }

            if showProBanner {
                ProBanner()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.bouncy) { showProBanner = false }
                        }
                    }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("sArCaSm GiFsS")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(Color(red: 0.71, green: 0.94, blue: 0.31))
            Spacer()
            if !isPro {
                Text("Free Pack")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }

    private func handleTap(_ phrase: GifPhrase) {
        if !phrase.isFree && !isPro {
            withAnimation(.bouncy) { showProBanner = true }
            return
        }
        withAnimation(.spring(duration: 0.15)) { inserting = phrase.id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onSelect(phrase)
            withAnimation { inserting = nil }
        }
    }
}

private struct PhraseCard: View {
    let phrase: GifPhrase
    let isLocked: Bool
    let isInserting: Bool

    private let accent = Color(red: 0.71, green: 0.94, blue: 0.31)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(isInserting ? accent : Color(white: 0.2), lineWidth: isInserting ? 1.5 : 0.5)
                )

            SarcasmText(text: phrase.displayText)
                .padding(.vertical, 14)
                .padding(.horizontal, 8)

            if isLocked {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.black.opacity(0.55))
                VStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 0.95, green: 0.70, blue: 0.25))
                    Text("Pro")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color(red: 0.95, green: 0.70, blue: 0.25))
                }
            }
        }
        .scaleEffect(isInserting ? 0.93 : 1.0)
        .animation(.spring(duration: 0.2), value: isInserting)
        .frame(height: 70)
    }
}

private struct SarcasmText: View {
    let text: String

    private let accent = Color(red: 0.71, green: 0.94, blue: 0.31)
    private let pale   = Color(white: 0.9)

    var body: some View {
        let chars = Array(text)
        // Build inline attributed-style layout via concatenated Text views
        chars.enumerated().reduce(Text("")) { result, pair in
            let (i, ch) = pair
            return result + Text(String(ch))
                .foregroundStyle(i % 2 == 0 ? accent : pale)
        }
        .font(.system(size: dynamicSize, weight: .heavy, design: .default))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.6)
    }

    private var dynamicSize: CGFloat {
        text.count <= 5 ? 20 : text.count <= 9 ? 17 : 14
    }
}

private struct ProBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .foregroundStyle(Color(red: 0.95, green: 0.70, blue: 0.25))
            Text("Unlock all GIFs with Sarcasm Pro")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.bottom, 12)
    }
}
