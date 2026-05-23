import SwiftUI
import SarcasmKit
import UIKit

struct HistoryView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var entries: [HistoryEntry] = []
    @State private var showCopiedToast = false
    @State private var showClearConfirmation = false

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "Nothing yet",
                    systemImage: "text.alignleft",
                    description: Text("Your transformed text shows up here once you start typing.")
                )
            } else {
                List {
                    ForEach(entries) { entry in
                        Button {
                            copy(entry)
                        } label: {
                            HistoryRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                copy(entry)
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            Button(role: .destructive) {
                                delete(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !entries.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Text("Clear")
                    }
                }
            }
        }
        .confirmationDialog(
            "Clear all history?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                HistoryStore.clear()
                refresh()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every entry. It can't be undone.")
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                copiedToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 32)
            }
        }
        .task { refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refresh() }
        }
    }

    private var copiedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
            Text("Copied")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: Capsule())
        .shadow(radius: 4, y: 2)
    }

    private func copy(_ entry: HistoryEntry) {
        UIPasteboard.general.string = entry.output
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopiedToast = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopiedToast = false
            }
        }
    }

    private func delete(_ entry: HistoryEntry) {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        HistoryStore.delete(id: entry.id)
        refresh()
    }

    private func refresh() {
        entries = HistoryStore.load().reversed()
    }
}
