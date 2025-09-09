import SwiftUI

struct WeightSlider: View {
    @Binding var weight: Double?
    let initialWeight: Double
    var rangeSpan: Double = 2.0

    // MARK: - Private Constants
    private let padding: CGFloat = 2
    private let thumbWidth: CGFloat = 50
    private let trackPadding: CGFloat = 5 // Safe margin inside the track

    // MARK: - Computed Properties
    private var allPossibleWeights: [Double] {
        let lowerBound = max(30.0, initialWeight - rangeSpan)
        let upperBound = min(200.0, initialWeight + rangeSpan)
        return Array(stride(from: lowerBound, through: upperBound, by: 0.1))
    }

    private var majorMarks: [Double] {
        var marks: [Double] = []
        let lower = Int(floor(initialWeight - rangeSpan))
        let upper = Int(ceil(initialWeight + rangeSpan))
        for i in lower...upper {
            if i >= 30 && i <= 200 {
                marks.append(Double(i))
            }
        }
        return marks.sorted()
    }

    // MARK: - State
    @State private var lastDragThumbCenter: CGFloat = 0
    private let feedbackGenerator = UISelectionFeedbackGenerator()

    // MARK: - Init
    init(weight: Binding<Double?>, initialWeight: Double) {
        self._weight = weight
        self.initialWeight = initialWeight
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            let sliderWidth = geometry.size.width - 2 * padding
            
            ZStack {
                // The slider content view
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 60)

                    // Tick Marks
                    ForEach(0..<allPossibleWeights.count, id: \.self) { index in
                        let markValue = allPossibleWeights[index]
                        let isMajor = majorMarks.contains(markValue)
                        Rectangle()
                            .fill(Color.gray.opacity(isMajor ? 0.8 : 0.4))
                            .frame(width: 1, height: isMajor ? 12 : 10)
                            .offset(x: positionForValue(markValue, sliderWidth: sliderWidth) - 0.5)
                    }

                    // Major Mark Labels
                    ForEach(majorMarks, id: \.self) { markValue in
                        VStack(spacing: 2) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.8))
                                .frame(width: 1, height: 8)
                            Text(String(format: "%.0f", markValue))
                                .font(.caption)
                                .foregroundColor(getMarkColor(for: markValue))
                        }
                        .frame(width: thumbWidth)
                        .offset(x: positionForValue(markValue, sliderWidth: sliderWidth) - (thumbWidth / 2))
                        .offset(y: 15)
                    }
                    
                    // Initial Weight Marker
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .offset(x: positionForValue(initialWeight, sliderWidth: sliderWidth) - 3)
                        .offset(y: -10)

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbWidth, height: thumbWidth)
                        .overlay(Text(getThumbText()).font(.headline).foregroundColor(.black))
                        .offset(x: getThumbXOffset(sliderWidth: sliderWidth))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let newThumbCenterX = lastDragThumbCenter + gesture.translation.width
                                    let trackStart = (thumbWidth / 2) + trackPadding
                                    let trackEnd = sliderWidth - (thumbWidth / 2) - trackPadding
                                    let clampedX = max(trackStart, min(newThumbCenterX, trackEnd))
                                    
                                    let continuousValue = valueForPosition(clampedX, sliderWidth: sliderWidth)
                                    let snappedValue = round(continuousValue * 10) / 10.0
                                    
                                    if self.weight != snappedValue {
                                        self.weight = snappedValue
                                        self.feedbackGenerator.selectionChanged()
                                    }
                                }
                                .onEnded { gesture in
                                    if let w = weight {
                                        lastDragThumbCenter = positionForValue(w, sliderWidth: sliderWidth)
                                    }
                                }
                        )
                }
                .frame(width: sliderWidth)
            }
            .frame(width: geometry.size.width)
            .onAppear {
                weight = initialWeight
                lastDragThumbCenter = positionForValue(initialWeight, sliderWidth: sliderWidth)
                feedbackGenerator.prepare()
            }
        }
        .frame(height: 80)
    }

    // MARK: - Helper Functions

    private func getMarkColor(for mark: Double?) -> Color {
        if let m = mark, m == initialWeight {
            return .black
        } else if let currentWeight = weight, let m = mark, abs(currentWeight - m) < 0.5 {
            return .black.opacity(0.8)
        }
        return .gray
    }

    private func getThumbText() -> String {
        if let w = weight { return String(format: "%.1f", w) }
        return "关"
    }

    private func positionForValue(_ value: Double, sliderWidth: CGFloat) -> CGFloat {
        let valueRange = (initialWeight + rangeSpan) - (initialWeight - rangeSpan)
        guard valueRange != 0 else { return sliderWidth / 2 }
        
        let ratio = (value - (initialWeight - rangeSpan)) / valueRange
        let trackWidth = sliderWidth - thumbWidth - (2 * trackPadding)
        let trackStart = (thumbWidth / 2) + trackPadding
        
        return trackStart + (ratio * trackWidth)
    }

    private func valueForPosition(_ x: CGFloat, sliderWidth: CGFloat) -> Double {
        let trackWidth = sliderWidth - thumbWidth - (2 * trackPadding)
        let trackStart = (thumbWidth / 2) + trackPadding
        let relativeX = x - trackStart
        let ratio = max(0, min(1, relativeX / trackWidth))
        
        let valueRange = (initialWeight + rangeSpan) - (initialWeight - rangeSpan)
        let value = (initialWeight - rangeSpan) + ratio * valueRange
        return value
    }

    private func getThumbXOffset(sliderWidth: CGFloat) -> CGFloat {
        let centerX = getThumbCenterX(sliderWidth: sliderWidth)
        return centerX - thumbWidth / 2
    }
    
    private func getThumbCenterX(sliderWidth: CGFloat) -> CGFloat {
        if let w = weight {
            return positionForValue(w, sliderWidth: sliderWidth)
        }
        return positionForValue(initialWeight, sliderWidth: sliderWidth)
    }
}