import SwiftUI

@MainActor
class HistoryManager: ObservableObject {
    @Published var transcripts: [Transcript] = []
    
    private let fileURL: URL
    
    init() {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        let hushDir = home.appendingPathComponent(".hush")
        try? fileManager.createDirectory(at: hushDir, withIntermediateDirectories: true)
        self.fileURL = hushDir.appendingPathComponent("history.json")
        
        load()
    }
    
    func add(text: String) {
        let transcript = Transcript(text: text)
        // Prepend logic
        DispatchQueue.main.async {
            self.transcripts.insert(transcript, at: 0)
            self.save()
        }
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.transcripts.removeAll()
            self.save()
        }
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(transcripts)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
    
    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let items = try? JSONDecoder().decode([Transcript].self, from: data) {
            self.transcripts = items
        }
    }
}
