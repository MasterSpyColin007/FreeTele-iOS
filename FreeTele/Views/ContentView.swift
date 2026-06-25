import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject var cameraVM = CameraViewModel()
    @StateObject var teleprompterVM = TeleprompterViewModel()
    @State var settings = RecordingSettings.default
    @State var isRecording = false
    @State var script = TeleprompterScript(content: "")
    @State var showSettings = false

    var body: some View {
        HomeView(
            script: $script,
            isRecording: $isRecording,
            showSettings: $showSettings
        )
        .fullScreenCover(isPresented: $isRecording) {
            RecordingView(
                cameraVM: cameraVM,
                teleprompterVM: teleprompterVM,
                settings: $settings,
                script: script
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: $settings)
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
