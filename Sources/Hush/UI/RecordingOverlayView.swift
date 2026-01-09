
import SwiftUI

struct RecordingOverlayView: View {
    @ObservedObject var viewModel: RecordingOverlayModel

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(0..<viewModel.barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 4, height: 4 + viewModel.barHeights[index] * 26)
                    .animation(.easeInOut(duration: 0.1), value: viewModel.barHeights[index])
            }
        }
        .frame(height: 32)
        .padding(8)
        .glassEffect(.clear, in: .capsule)  // .clear variant = high transparency
        .compositingGroup()  // Flatten to prevent rendering artifacts
    }
}

@MainActor
class RecordingOverlayModel: ObservableObject {
    @Published var barHeights: [CGFloat]
    let barCount = 7 // Odd number looks good for symmetry
    
    init() {
        self.barHeights = Array(repeating: 0.1, count: 7)
    }
    
    func updateLevel(_ level: Float) {
        // Level is 0.0 to 1.0
        // We want to update bars to look like a visualizer
        // Center bars higher, outer bars lower
        
        let cgLevel = CGFloat(level)
        
        var newHeights: [CGFloat] = []
        for i in 0..<barCount {
            // Distance from center
            let center = CGFloat(barCount - 1) / 2.0
            let dist = abs(CGFloat(i) - center)
            let maxDist = center
            
            // Attenuate based on distance from center (Gaussian-ish)
            let scale = 1.0 - (dist / (maxDist + 1))
            
            // Add some randomness
            let randomVar = CGFloat.random(in: 0.8...1.2)
            
            let height = max(0.05, cgLevel * scale * randomVar)
            newHeights.append(height)
        }
        
        self.barHeights = newHeights
    }
}
