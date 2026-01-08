import Foundation

struct Transcript: Identifiable, Codable {
    var id: UUID
    var timestamp: Date
    var text: String
    var appContext: String?
    
    init(text: String, appContext: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.text = text
        self.appContext = appContext
    }
}
