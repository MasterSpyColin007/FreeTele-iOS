import SwiftUI

struct TeleprompterOverlay: View {
    let script: String
    let scrollSpeed: Double
    let textSize: Double
    let textColor: Color
    let backgroundOpacity: Double
    let isMirrored: Bool
    let isScrolling: Bool

    @State private var scrollOffset: CGFloat = 0
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(backgroundOpacity)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Text(script)
                        .font(.system(size: textSize, weight: .bold, design: .default))
                        .foregroundColor(textColor)
                        .lineSpacing(textSize * 0.5)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .offset(y: -scrollOffset)
                .frame(height: geometry.size.height)
                .clipped()

                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0),
                            Color.black.opacity(backgroundOpacity)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                }
            }
        }
        .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if isScrolling {
                scrollOffset += CGFloat(scrollSpeed * 2.5)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct TeleprompterOverlay_Previews: PreviewProvider {
    static var previews: some View {
        TeleprompterOverlay(
            script: "This is a sample teleprompter script. It scrolls upward continuously so the reader can follow along while looking at the camera.",
            scrollSpeed: 1.0,
            textSize: 24,
            textColor: .white,
            backgroundOpacity: 0.5,
            isMirrored: false,
            isScrolling: true
        )
        .frame(height: 300)
        .background(Color.black)
    }
}
