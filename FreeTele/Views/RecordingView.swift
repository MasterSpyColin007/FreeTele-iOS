import SwiftUI
import AVFoundation

struct RecordingView: View {
    @ObservedObject var cameraVM: CameraViewModel
    @ObservedObject var teleprompterVM: TeleprompterViewModel
    @Binding var settings: RecordingSettings
    let script: TeleprompterScript

    @Environment(\.dismiss) private var dismiss

    @State private var showSavedToast = false

    private var formattedTime: String {
        let totalSeconds = Int(cameraVM.recordingTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            CameraPreviewView(
                session: cameraVM.session,
                isMirrored: settings.cameraPosition == .front
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TeleprompterOverlay(
                    script: script.content,
                    scrollSpeed: settings.scrollSpeed,
                    textSize: settings.textSize,
                    textColor: settings.textColor.swiftUIColor,
                    backgroundOpacity: settings.backgroundOpacity,
                    isMirrored: settings.isMirrored,
                    isScrolling: true
                )
                .frame(height: UIScreen.main.bounds.height * 0.42)

                Spacer()
            }

            VStack {
                HStack {
                    Button(action: {
                        if cameraVM.isRecording {
                            cameraVM.stopRecording()
                        }
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding()

                Spacer()
            }

            VStack {
                Spacer()

                VStack(spacing: 16) {
                    Text(formattedTime)
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)

                    HStack(spacing: 40) {
                        Button(action: {
                            cameraVM.toggleCamera()
                            settings.cameraPosition = cameraVM.currentCamera
                        }) {
                            Image(systemName: "camera.rotate")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Button(action: {
                            if cameraVM.isRecording {
                                cameraVM.stopRecording()
                            } else {
                                cameraVM.startRecording()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(cameraVM.isRecording ? Color.red : Color.white)
                                    .frame(width: 80, height: 80)

                                if cameraVM.isRecording {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .frame(width: 24, height: 24)
                                }
                            }
                        }

                        Spacer()

                        Color.clear
                            .frame(width: 52, height: 52)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
            }

            if showSavedToast {
                VStack {
                    Spacer()
                    Text("Saved to Photos")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.bottom, 140)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: showSavedToast)
            }
        }
        .onAppear {
            cameraVM.startSession()
            teleprompterVM.startScrolling()
        }
        .onDisappear {
            if cameraVM.isRecording {
                cameraVM.stopRecording()
            }
            cameraVM.stopSession()
            teleprompterVM.stopScrolling()
        }
        .onChange(of: cameraVM.isRecording) { isRecording in
            if !isRecording && cameraVM.recordingTime > 0 {
                showSavedToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showSavedToast = false
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView(
            cameraVM: CameraViewModel(),
            teleprompterVM: TeleprompterViewModel(),
            settings: .constant(RecordingSettings.default),
            script: TeleprompterScript(content: "Sample script for preview")
        )
    }
}
