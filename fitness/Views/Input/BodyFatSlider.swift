import SwiftUI

struct BodyFatSlider: View {
    @Binding var percentage: Double?
    let initialPercentage: Double
    var rangeSpan: Double = 2.5 // More appropriate range for body fat

    // MARK: - Private Constants
    private let padding: CGFloat = 2
    private let thumbWidth: CGFloat = 50
    private let trackPadding: CGFloat = 5 // Safe margin inside the track

    // MARK: - Computed Properties
    private var allPossiblePercentages: [Double] {
        let lowerBound = max(3.0, initialPercentage - rangeSpan)
        let upperBound = min(50.0, initialPercentage + rangeSpan)
        return Array(stride(from: lowerBound, through: upperBound, by: 0.1))
    }

    private var majorMarks: [Double] {
        var marks: [Double] = []
        let actualLowerBound = max(3.0, initialPercentage - rangeSpan)
        let actualUpperBound = min(50.0, initialPercentage + rangeSpan)

        let lowerInt = Int(ceil(actualLowerBound))
        let upperInt = Int(floor(actualUpperBound))

        for i in lowerInt...upperInt {
            marks.append(Double(i))
        }
        return marks.sorted()
    }

    private var halfMajorMarks: [Double] {
        return allPossiblePercentages.filter { isHalfMajor($0) }
    }

    // MARK: - State
    private let feedbackGenerator = UISelectionFeedbackGenerator()

    // MARK: - Init
    init(percentage: Binding<Double?>, initialPercentage: Double) {
        self._percentage = percentage
        self.initialPercentage = initialPercentage
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
                    ForEach(0..<allPossiblePercentages.count, id: \.self) { index in
                        let markValue = allPossiblePercentages[index]
                        let isMajor = majorMarks.contains(markValue)
                        let isHalf = isHalfMajor(markValue)
                        let tickHeight: CGFloat = isMajor ? 16 : (isHalf ? 13 : 10)
                        Rectangle()
                            .fill(Color.gray.opacity(isMajor ? 0.8 : (isHalf ? 0.6 : 0.4)))
                            .frame(width: 1, height: tickHeight)
                            .offset(x: positionForValue(markValue, sliderWidth: sliderWidth) - 0.5)
                    }

                    // Major Mark Labels
                    ForEach(majorMarks, id: \.self) { markValue in
                        VStack(spacing: 2) {
                            Text(String(format: "%.0f%%", markValue))
                                .font(.caption)
                                .foregroundColor(getMarkColor(for: markValue))
                        }
                        .frame(width: thumbWidth)
                        .offset(x: positionForValue(markValue, sliderWidth: sliderWidth) - (thumbWidth / 2))
                        .offset(y: 15)
                    }
                    
                    // Initial Percentage Marker
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .offset(x: positionForValue(initialPercentage, sliderWidth: sliderWidth) - 3)
                        .offset(y: -10)

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbWidth, height: thumbWidth)
                        .overlay(Text(getThumbText()).font(.headline).foregroundColor(.black))
                        .offset(x: getThumbXOffset(sliderWidth: sliderWidth))
                }
                .frame(width: sliderWidth)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let newThumbCenterX = gesture.location.x
                            let trackStart = (thumbWidth / 2) + trackPadding
                            let trackEnd = sliderWidth - (thumbWidth / 2) - trackPadding
                            let clampedX = max(trackStart, min(newThumbCenterX, trackEnd))
                            
                            let continuousValue = valueForPosition(clampedX, sliderWidth: sliderWidth)
                            let snappedValue = round(continuousValue * 10) / 10.0
                            
                            if self.percentage != snappedValue {
                                self.percentage = snappedValue
                                self.feedbackGenerator.selectionChanged()
                            }
                        }
                )
            }
            .frame(width: geometry.size.width)
            .onAppear {
                percentage = initialPercentage
                feedbackGenerator.prepare()
            }
        }
        .frame(height: 80)
    }

    // MARK: - Helper Functions

    private func getMarkColor(for mark: Double?) -> Color {
        if let m = mark, m == initialPercentage {
            return .black
        } else if let currentPercentage = percentage, let m = mark, abs(currentPercentage - m) < 0.5 {
            return .black.opacity(0.8)
        }
        return .gray
    }

    private func getThumbText() -> String {
        if let p = percentage { return String(format: "%.1f", p) }
        return "关"
    }

    private func positionForValue(_ value: Double, sliderWidth: CGFloat) -> CGFloat {
        let valueRange = (initialPercentage + rangeSpan) - (initialPercentage - rangeSpan)
        guard valueRange != 0 else { return sliderWidth / 2 }
        
        let ratio = (value - (initialPercentage - rangeSpan)) / valueRange
        let trackWidth = sliderWidth - thumbWidth - (2 * trackPadding)
        let trackStart = (thumbWidth / 2) + trackPadding
        
        return trackStart + (ratio * trackWidth)
    }

    private func valueForPosition(_ x: CGFloat, sliderWidth: CGFloat) -> Double {
        let trackWidth = sliderWidth - thumbWidth - (2 * trackPadding)
        let trackStart = (thumbWidth / 2) + trackPadding
        let relativeX = x - trackStart
        let ratio = max(0, min(1, relativeX / trackWidth))
        
        let valueRange = (initialPercentage + rangeSpan) - (initialPercentage - rangeSpan)
        let value = (initialPercentage - rangeSpan) + ratio * valueRange
        return value
    }

    private func getThumbXOffset(sliderWidth: CGFloat) -> CGFloat {
        let centerX = getThumbCenterX(sliderWidth: sliderWidth)
        return centerX - thumbWidth / 2
    }
    
    private func getThumbCenterX(sliderWidth: CGFloat) -> CGFloat {
        if let p = percentage {
            return positionForValue(p, sliderWidth: sliderWidth)
        }
        return positionForValue(initialPercentage, sliderWidth: sliderWidth)
    }

    private func isHalfMajor(_ value: Double) -> Bool {
        return value.truncatingRemainder(dividingBy: 1.0) == 0.5
    }
}
