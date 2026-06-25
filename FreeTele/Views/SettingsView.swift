import SwiftUI

struct SettingsView: View {
    @Binding var settings: RecordingSettings
    @Environment(\.dismiss) private var dismiss

    private let backgroundDark = Color(red: 0.059, green: 0.059, blue: 0.102)
    private let secondaryDark = Color(red: 0.102, green: 0.102, blue: 0.18)
    private let primaryOrange = Color(red: 1.0, green: 0.42, blue: 0.21)

    var body: some View {
        NavigationView {
            ZStack {
                backgroundDark.ignoresSafeArea()

                Form {
                    Section {
                        Picker("Camera", selection: $settings.cameraPosition) {
                            Text("Front Camera").tag(RecordingSettings.CameraPosition.front)
                            Text("Back Camera").tag(RecordingSettings.CameraPosition.back)
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Camera Selection")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scroll Speed: \(String(format: "%.1f", settings.scrollSpeed))x")
                                .font(.subheadline)
                            Slider(
                                value: $settings.scrollSpeed,
                                in: 0.5...3.0,
                                step: 0.1
                            )
                            .tint(primaryOrange)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Scroll Speed")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Text Size: \(Int(settings.textSize)) pt")
                                .font(.subheadline)
                            Slider(
                                value: $settings.textSize,
                                in: 16...48,
                                step: 1
                            )
                            .tint(primaryOrange)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Text Size")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Section {
                        HStack(spacing: 20) {
                            ForEach(RecordingSettings.TeleprompterColor.allCases, id: \.self) { color in
                                Button(action: {
                                    settings.textColor = color
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(color.swiftUIColor)
                                            .frame(width: 44, height: 44)

                                        if settings.textColor == color {
                                            Circle()
                                                .stroke(Color.white, lineWidth: 3)
                                                .frame(width: 50, height: 50)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Text Color")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Background Opacity: \(Int(settings.backgroundOpacity * 100))%")
                                .font(.subheadline)
                            Slider(
                                value: $settings.backgroundOpacity,
                                in: 0.0...0.8,
                                step: 0.05
                            )
                            .tint(primaryOrange)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Background Opacity")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Section {
                        Toggle("Mirror Text", isOn: $settings.isMirrored)
                            .tint(primaryOrange)
                    } header: {
                        Text("Mirror Text")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Section {
                        Button(action: {
                            settings = RecordingSettings.default
                        }) {
                            Text("Reset to Defaults")
                                .foregroundColor(primaryOrange)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(backgroundDark)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(primaryOrange)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settings: .constant(RecordingSettings.default))
    }
}
