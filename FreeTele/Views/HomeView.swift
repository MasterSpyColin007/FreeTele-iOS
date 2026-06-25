import SwiftUI

struct HomeView: View {
    @Binding var script: TeleprompterScript
    @Binding var isRecording: Bool
    @Binding var showSettings: Bool

    private let primaryOrange = Color(red: 1.0, green: 0.42, blue: 0.21)
    private let backgroundDark = Color(red: 0.059, green: 0.059, blue: 0.102)
    private let secondaryDark = Color(red: 0.102, green: 0.102, blue: 0.18)

    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Text("Free Tele")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(primaryOrange)

                    HStack {
                        Spacer()
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(secondaryDark)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 10)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(secondaryDark)

                    TextEditor(text: $script.content)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(16)
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)

                    if script.content.isEmpty {
                        Text("Paste your script here...")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.35))
                            .padding(.top, 24)
                            .padding(.leading, 24)
                    }
                }
                .frame(maxHeight: .infinity)

                HStack {
                    Spacer()
                    Text("\(script.content.count) characters")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)

                Button(action: {
                    isRecording = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "record.circle.fill")
                            .font(.title3)
                        Text("Start Recording")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        script.content.isEmpty
                        ? Color.gray.opacity(0.4)
                        : primaryOrange
                    )
                    .cornerRadius(16)
                }
                .disabled(script.content.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top, 16)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            script: .constant(TeleprompterScript(content: "Sample script")),
            isRecording: .constant(false),
            showSettings: .constant(false)
        )
    }
}
