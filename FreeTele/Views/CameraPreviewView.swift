import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    var isMirrored: Bool = false

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = videoGravity
        previewLayer.frame = view.bounds
        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        previewLayer.connection?.isVideoMirrored = isMirrored

        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer

        context.coordinator.updateOrientation()

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
        context.coordinator.previewLayer?.connection?.isVideoMirrored = isMirrored
        context.coordinator.updateOrientation()
    }

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        NotificationCenter.default.addObserver(
            coordinator,
            selector: #selector(Coordinator.orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        return coordinator
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator)
    }

    class Coordinator: NSObject {
        var previewLayer: AVCaptureVideoPreviewLayer?

        @objc func orientationDidChange() {
            updateOrientation()
        }

        func updateOrientation() {
            guard let previewLayer = previewLayer else { return }
            guard let connection = previewLayer.connection else { return }

            if connection.isVideoOrientationSupported {
                let deviceOrientation = UIDevice.current.orientation
                let videoOrientation: AVCaptureVideoOrientation

                switch deviceOrientation {
                case .portrait:
                    videoOrientation = .portrait
                case .landscapeLeft:
                    videoOrientation = .landscapeRight
                case .landscapeRight:
                    videoOrientation = .landscapeLeft
                case .portraitUpsideDown:
                    videoOrientation = .portraitUpsideDown
                default:
                    videoOrientation = .portrait
                }

                connection.videoOrientation = videoOrientation
            }
        }
    }
}

struct CameraPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        CameraPreviewView(session: AVCaptureSession())
            .ignoresSafeArea()
    }
}
