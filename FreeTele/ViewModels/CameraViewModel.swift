import Foundation
import SwiftUI
import AVFoundation
import Photos

@MainActor
class CameraViewModel: ObservableObject {
    
    @Published var isRecording: Bool = false
    @Published var isReady: Bool = false
    @Published var recordingTime: TimeInterval = 0
    @Published var currentCamera: RecordingSettings.CameraPosition = .back
    @Published var errorMessage: String? = nil
    @Published var showSavedToast: Bool = false
    
    private var cameraService: CameraService
    private var photoLibraryService: PhotoLibraryService
    private var timer: Timer?
    private var recordingStartTime: Date?
    
    var session: AVCaptureSession { cameraService.session }
    
    init() {
        self.cameraService = CameraService()
        self.photoLibraryService = PhotoLibraryService()
    }
    
    func setupSession(settings: RecordingSettings) {
        Task { @MainActor in
            let success = cameraService.setupSession(position: settings.cameraPositionAV())
            if success {
                self.isReady = true
                self.currentCamera = settings.cameraPosition
            } else {
                self.errorMessage = "Failed to setup camera session."
            }
        }
    }
    
    func startSession() {
        cameraService.startSession()
    }
    
    func stopSession() {
        cameraService.stopSession()
        stopRecordingTimer()
    }
    
    func toggleCamera() {
        cameraService.switchCamera()
        currentCamera = (currentCamera == .back) ? .front : .back
    }
    
    func startRecording() {
        guard !isRecording else { return }
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        cameraService.startRecording(to: tempURL)
        isRecording = true
        recordingStartTime = Date()
        startRecordingTimer()
    }
    
    func stopRecording() {
        guard isRecording else { return }
        stopRecordingTimer()
        isRecording = false
        Task { @MainActor in
            do {
                if let videoURL = try await cameraService.stopRecording() {
                    await saveVideoToLibrary(videoURL: videoURL)
                } else {
                    errorMessage = "Recording failed to produce a valid file."
                }
            } catch {
                errorMessage = "Recording error: \(error.localizedDescription)"
            }
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecordingTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            self.recordingTime = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopRecordingTimer() {
        timer?.invalidate()
        timer = nil
        recordingTime = 0
        recordingStartTime = nil
    }
    
    private func saveVideoToLibrary(videoURL: URL) async {
        do {
            try await photoLibraryService.saveVideo(from: videoURL)
            showSavedToast()
            cleanupTempFile(videoURL)
        } catch {
            errorMessage = "Failed to save video: \(error.localizedDescription)"
            cleanupTempFile(videoURL)
        }
    }
    
    private func showSavedToast() {
        showSavedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showSavedToast = false
        }
    }
    
    private func cleanupTempFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    deinit {
        timer?.invalidate()
    }
}
