import Foundation
import SwiftUI
import AVFoundation

struct RecordingSettings: Codable, Equatable {
    
    enum CameraPosition: String, Codable, CaseIterable {
        case front
        case back
    }
    
    enum TeleprompterColor: String, Codable, CaseIterable {
        case white
        case yellow
        case green
        case cyan
    }
    
    var cameraPosition: CameraPosition
    var scrollSpeed: Double
    var textSize: Double
    var textColor: TeleprompterColor
    var backgroundOpacity: Double
    var isMirrored: Bool
    
    static let `default` = RecordingSettings(
        cameraPosition: .back,
        scrollSpeed: 1.0,
        textSize: 24.0,
        textColor: .white,
        backgroundOpacity: 0.5,
        isMirrored: false
    )
    
    func color() -> Color {
        switch textColor {
        case .white:
            return .white
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .cyan:
            return .cyan
        }
    }
    
    func cameraPositionAV() -> AVCaptureDevice.Position {
        switch cameraPosition {
        case .front:
            return .front
        case .back:
            return .back
        }
    }
}

extension RecordingSettings.TeleprompterColor {
    var swiftUIColor: Color {
        switch self {
        case .white:
            return .white
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .cyan:
            return Color(red: 0.0, green: 0.85, blue: 1.0)
        }
    }

    var displayName: String {
        switch self {
        case .white: return "White"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .cyan: return "Cyan"
        }
    }
}
