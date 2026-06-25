import Foundation
import SwiftUI
import Combine

class TeleprompterViewModel: ObservableObject {
    
    @Published var script: TeleprompterScript = .empty
    @Published var isScrolling: Bool = false
    @Published var scrollOffset: CGFloat = 0
    @Published var settings: RecordingSettings = .default
    
    private var scrollTimer: Timer?
    private var totalScrollHeight: CGFloat = 0
    
    private let scrollTickInterval: TimeInterval = 0.05
    private let baseScrollPixelsPerSecond: CGFloat = 50.0
    
    func startScrolling() {
        guard !isScrolling else { return }
        isScrolling = true
        scrollTimer?.invalidate()
        scrollTimer = Timer.scheduledTimer(withTimeInterval: scrollTickInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let tickScrollAmount = self.baseScrollPixelsPerSecond * CGFloat(self.settings.scrollSpeed) * CGFloat(self.scrollTickInterval)
            self.scrollOffset += tickScrollAmount
        }
    }
    
    func stopScrolling() {
        isScrolling = false
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
    
    func resetScroll() {
        stopScrolling()
        scrollOffset = 0
    }
    
    func updateScript(_ script: TeleprompterScript) {
        self.script = script
    }
    
    func updateSettings(_ settings: RecordingSettings) {
        self.settings = settings
    }
    
    func estimatedDuration() -> TimeInterval {
        guard settings.scrollSpeed > 0 else { return 0 }
        let height = totalScrollHeight > 0 ? totalScrollHeight : estimatedScrollHeight()
        return TimeInterval(height / (baseScrollPixelsPerSecond * CGFloat(settings.scrollSpeed)))
    }
    
    private func estimatedScrollHeight() -> CGFloat {
        let estimatedLineCount = max(1, CGFloat(script.wordCount()) / 10)
        return estimatedLineCount * 30.0
    }
    
    func setTotalScrollHeight(_ height: CGFloat) {
        totalScrollHeight = height
    }
    
    deinit {
        scrollTimer?.invalidate()
    }
}
