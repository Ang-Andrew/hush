import SwiftUI
import AppKit

struct HistoryView: View {
    @EnvironmentObject var historyManager: HistoryManager

    var body: some View {
        List {
            ForEach(historyManager.transcripts) { item in
                TranscriptRow(item: item)
            }
        }
        .navigationTitle("Dictation History")
        .frame(minWidth: 400, minHeight: 600)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(role: .destructive) {
                    historyManager.clear()
                } label: {
                    Image(systemName: "trash")
                }
                .help("Clear History")
            }
        }
    }
}

struct TranscriptRow: View {
    let item: Transcript
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.timestamp, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(item.text, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
            }

            Text(item.text)
                .lineLimit(isExpanded ? nil : 2)
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
        }
        .padding()
    }
}
