import SwiftUI

struct FaceView: View {
    let state: SessionStatus.SessionState
    let tokenPercentage: Double
    
    @State private var blinkOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color based on state
                backgroundColor
                    .ignoresSafeArea()
                
                // Subtle gradient overlay
                LinearGradient(
                    colors: [
                        backgroundColor.opacity(0.8),
                        backgroundColor.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // The Face
                VStack(spacing: geometry.size.width * 0.15) {
                    // Eyes row
                    HStack(spacing: geometry.size.width * 0.2) {
                        EyeView(state: state, isLeft: true)
                        EyeView(state: state, isLeft: false)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Token usage indicator (subtle corner bars)
                VStack {
                    HStack {
                        Spacer()
                        TokenIndicator(percentage: tokenPercentage)
                            .padding(8)
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            startBlinkAnimation()
            if state == .thinking {
                startPulseAnimation()
            }
        }
    }
    
    private var backgroundColor: Color {
        switch state {
        case .idle:
            return Color(red: 0.85, green: 0.87, blue: 0.91) // Soft blue-gray
        case .thinking:
            return Color(red: 0.96, green: 0.72, blue: 0.72) // Warm pink/salmon
        case .talking:
            return Color(red: 0.72, green: 0.89, blue: 0.72) // Soft green
        case .error:
            return Color(red: 0.95, green: 0.42, blue: 0.42) // Alert red
        case .offline:
            return Color(red: 0.4, green: 0.4, blue: 0.4) // Dimmed gray
        }
    }
    
    private func startBlinkAnimation() {
        guard state != .offline else { return }
        
        // Random blink every 3-7 seconds
        let delay = Double.random(in: 3...7)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.1)) {
                blinkOffset = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeIn(duration: 0.1)) {
                    blinkOffset = 0
                }
                startBlinkAnimation()
            }
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
    }
}

// MARK: - Eye View
struct EyeView: View {
    let state: SessionStatus.SessionState
    let isLeft: Bool
    
    @State private var lookOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            RoundedRectangle(cornerRadius: size * 0.05)
                .fill(Color.black)
                .frame(width: size, height: eyeHeight(for: size))
                .offset(lookOffset)
                .onAppear {
                    startLookingAnimation()
                }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func eyeHeight(for size: CGFloat) -> CGFloat {
        switch state {
        case .thinking:
            return size * 0.3 // Narrow when thinking
        case .talking:
            return size * 1.1 // Wide when active
        case .error:
            return size * 0.8 // Slightly concerned
        default:
            return size // Normal
        }
    }
    
    private func startLookingAnimation() {
        guard state != .offline else { return }
        
        // Subtle look direction shifts
        let directions: [CGSize] = [
            .zero,
            CGSize(width: 2, height: 0),
            CGSize(width: -2, height: 0),
            .zero
        ]
        
        var index = 0
        Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                lookOffset = directions[index]
            }
            index = (index + 1) % directions.count
        }
    }
}

// MARK: - Token Indicator
struct TokenIndicator: View {
    let percentage: Double
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<3) { i in
                let threshold = Double(i + 1) * 0.33
                let isActive = percentage >= threshold
                
                RoundedRectangle(cornerRadius: 1)
                    .fill(isActive ? Color.black.opacity(0.6) : Color.black.opacity(0.15))
                    .frame(width: 12, height: 2)
            }
        }
    }
}
