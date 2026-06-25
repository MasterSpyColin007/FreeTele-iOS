import Photos
import UIKit
import Combine

class PhotoLibraryService: ObservableObject {

    @Published var isAuthorized: Bool = false
    @Published var lastSavedAsset: PHAsset?
    @Published var errorMessage: String?

    init() {
        self.isAuthorized = (PHPhotoLibrary.authorizationStatus(for: .addOnly) == .authorized)
            || (PHPhotoLibrary.authorizationStatus() == .authorized)
    }

    func requestAuthorization() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            let granted = (newStatus == .authorized)
            await MainActor.run {
                self.isAuthorized = granted
                if !granted {
                    self.errorMessage = "Photo library access is required to save videos."
                } else {
                    self.errorMessage = nil
                }
            }
            return granted
        case .authorized:
            await MainActor.run {
                self.isAuthorized = true
                self.errorMessage = nil
            }
            return true
        case .denied, .restricted, .limited:
            await MainActor.run {
                self.isAuthorized = false
                self.errorMessage = "Photo library access has been denied. Please enable it in Settings."
            }
            return false
        @unknown default:
            await MainActor.run {
                self.isAuthorized = false
                self.errorMessage = "Photo library authorization status is unknown."
            }
            return false
        }
    }

    func saveVideo(from url: URL) async throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            await MainActor.run {
                self.errorMessage = "The video file does not exist at the provided path."
            }
            throw PhotoLibraryServiceError.fileNotFound
        }
        guard await requestAuthorization() else {
            throw PhotoLibraryServiceError.notAuthorized
        }
        var localIdentifier: String?
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.creationDate = Date()
                request.addResource(with: .video, fileURL: url, options: nil)
                localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
            }
            if let localIdentifier = localIdentifier {
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
                if let asset = fetchResult.firstObject {
                    await MainActor.run {
                        self.lastSavedAsset = asset
                        self.errorMessage = nil
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to save video to Photos: \(error.localizedDescription)"
            }
            throw PhotoLibraryServiceError.saveFailed(underlying: error)
        }
    }
}

enum PhotoLibraryServiceError: LocalizedError {
    case fileNotFound
    case notAuthorized
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "The video file was not found."
        case .notAuthorized:
            return "Photo library access is not authorized."
        case .saveFailed(let underlying):
            return "Failed to save video: \(underlying.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "Please ensure the recording completed successfully before saving."
        case .notAuthorized:
            return "Enable photo library access in Settings to save videos."
        case .saveFailed:
            return "Please try again or check available storage."
        }
    }
}
