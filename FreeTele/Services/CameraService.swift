import AVFoundation
import UIKit
import Combine

class CameraService: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    
    @Published var isRunning: Bool = false
    @Published var isRecording: Bool = false
    @Published var isReady: Bool = false
    @Published var errorMessage: String?
    
    let session = AVCaptureSession()
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    private(set) var videoDeviceInput: AVCaptureDeviceInput?
    private(set) var movieFileOutput: AVCaptureMovieFileOutput?
    private(set) var currentPosition: AVCaptureDevice.Position = .back
    
    private let sessionQueue = DispatchQueue(label: "com.freetele.camera.session")
    
    private var recordedFileURL: URL?
    private var recordingFinishedContinuation: CheckedContinuation<URL?, Error>?
    
    override init() {
        super.init()
        previewLayer.videoGravity = .resizeAspectFill
    }
    
    deinit {
        stopSession()
    }
    
    @discardableResult
    func setupSession(position: AVCaptureDevice.Position) -> Bool {
        sessionQueue.sync {
            guard !session.isRunning else {
                DispatchQueue.main.async {
                    self.errorMessage = "Cannot reconfigure session while it is running."
                }
                return false
            }
            
            session.beginConfiguration()
            defer { session.commitConfiguration() }
            
            for input in session.inputs {
                session.removeInput(input)
            }
            for output in session.outputs {
                session.removeOutput(output)
            }
            
            session.sessionPreset = .high
            
            guard let videoDevice = self.discoverCamera(for: position) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Unable to find a camera for the requested position."
                }
                return false
            }
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if session.canAddInput(videoInput) {
                    session.addInput(videoInput)
                    self.videoDeviceInput = videoInput
                    self.currentPosition = position
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Cannot add video input to the capture session."
                    }
                    return false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create video input: \(error.localizedDescription)"
                }
                return false
            }
            
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Unable to find a microphone for recording."
                }
                return false
            }
            
            do {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Cannot add audio input to the capture session."
                    }
                    return false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create audio input: \(error.localizedDescription)"
                }
                return false
            }
            
            let movieOutput = AVCaptureMovieFileOutput()
            if session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
                self.movieFileOutput = movieOutput
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Cannot add movie file output to the capture session."
                }
                return false
            }
            
            previewLayer.session = session
            
            if position == .front {
                previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
                previewLayer.connection?.isVideoMirrored = true
            } else {
                previewLayer.connection?.automaticallyAdjustsVideoMirroring = true
                previewLayer.connection?.isVideoMirrored = false
            }
            
            DispatchQueue.main.async {
                self.isReady = true
                self.errorMessage = nil
            }
            
            return true
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.session.isRunning else { return }
            
            let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
            switch authStatus {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.startSessionOnQueue()
                    } else {
                        DispatchQueue.main.async {
                            self.errorMessage = "Camera access is required to record video."
                        }
                    }
                }
            case .authorized:
                self.startSessionOnQueue()
            case .denied, .restricted:
                DispatchQueue.main.async {
                    self.errorMessage = "Camera access has been denied. Please enable it in Settings."
                }
            @unknown default:
                DispatchQueue.main.async {
                    self.errorMessage = "Camera authorization status is unknown."
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isRunning = false
                self.isReady = false
            }
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            let newPosition: AVCaptureDevice.Position = (self.currentPosition == .back) ? .front : .back
            let success = self.setupSession(position: newPosition)
            if success, self.session.isRunning {
                self.startSessionOnQueue()
            }
        }
    }
    
    func startRecording(to url: URL) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard let movieOutput = self.movieFileOutput else {
                DispatchQueue.main.async {
                    self.errorMessage = "Movie file output is not configured."
                }
                return
            }
            guard !movieOutput.isRecording else {
                DispatchQueue.main.async {
                    self.errorMessage = "A recording is already in progress."
                }
                return
            }
            self.recordedFileURL = nil
            if !self.session.isRunning {
                self.startSessionOnQueue()
            }
            movieOutput.startRecording(to: url, recordingDelegate: self)
        }
    }
    
    func stopRecording() async throws -> URL? {
        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                guard let movieOutput = self.movieFileOutput, movieOutput.isRecording else {
                    continuation.resume(returning: self.recordedFileURL)
                    return
                }
                self.recordingFinishedContinuation = continuation
                movieOutput.stopRecording()
            }
        }
    }
    
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = true
            self?.errorMessage = nil
        }
    }
    
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            if let error = error as NSError? {
                if error.domain == "AVFoundationErrorDomain" && error.code == -11806 {
                    self?.errorMessage = nil
                    self?.recordedFileURL = outputFileURL
                    if let continuation = self?.recordingFinishedContinuation {
                        self?.recordingFinishedContinuation = nil
                        continuation.resume(returning: outputFileURL)
                    }
                } else {
                    self?.errorMessage = "Recording failed: \(error.localizedDescription)"
                    self?.recordedFileURL = nil
                    if let continuation = self?.recordingFinishedContinuation {
                        self?.recordingFinishedContinuation = nil
                        continuation.resume(throwing: error)
                    }
                }
            } else {
                self?.errorMessage = nil
                self?.recordedFileURL = outputFileURL
                if let continuation = self?.recordingFinishedContinuation {
                    self?.recordingFinishedContinuation = nil
                    continuation.resume(returning: outputFileURL)
                }
            }
        }
    }
    
    private func discoverCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTripleCamera],
            mediaType: .video,
            position: position
        )
        let devices = discoverySession.devices
        return devices.first(where: { $0.position == position }) ?? devices.first
    }
    
    private func startSessionOnQueue() {
        guard !session.isRunning else { return }
        session.startRunning()
        DispatchQueue.main.async { [weak self] in
            self?.isRunning = true
            self?.isReady = true
        }
    }
}
