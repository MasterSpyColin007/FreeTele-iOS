import Foundation

struct TeleprompterScript: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
    }
    
    static let empty = TeleprompterScript()
    
    func wordCount() -> Int {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        return trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    func characterCount() -> Int {
        return content.count
    }
    
    func estimatedReadingTime(at speed: Double) -> TimeInterval {
        guard speed > 0 else { return 0 }
        let words = Double(wordCount())
        let averageWordsPerSecond = 2.5 * speed
        return words / averageWordsPerSecond
    }
}
