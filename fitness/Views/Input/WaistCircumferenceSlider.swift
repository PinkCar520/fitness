import SwiftUI

struct WaistCircumferenceSlider: View {
    @Binding var circumference: Double?
    let initialCircumference: Double
    var rangeSpan: Double = 2.0

    // MARK: - Private Constants
    private let padding: CGFloat = 2
    private let thumbWidth: CGFloat = 50
    private let trackPadding: CGFloat = 5 // Safe margin inside the track

    // MARK: - Computed Properties
    private var allPossibleValues: [Double] {
        let lowerBound = max(50.0, initialCircumference - rangeSpan)
        let upperBound = min(150.0, initialCircumference + rangeSpan)
        return Array(stride(from: lowerBound, through: upperBound, by: 0.1))
    }

    private var majorMarks: [Double] {
        var marks: [Double] = []
        let actualLowerBound = max(50.0, initialCircumference - rangeSpan)
        let actualUpperBound = min(150.0, initialCircumference + rangeSpan)

        let lowerInt = Int(ceil(actualLowerBound))
        let upperInt = Int(floor(actualUpperBound))

        for i in lowerInt...upperInt {
            marks.append(Double(i))
        }
        return marks.sorted()
    }

    private var halfMajorMarks: [Double] {
        return allPossibleValues.filter { isHalfMajor($0) }
    }

    // MARK: - State
    private let feedbackGenerator = UISelectionFeedbackGenerator()

    // MARK: - Init
    init(circumference: Binding<Double?>, initialCircumference: Double) {
        self._circumference = circumference
        self.initialCircumference = initialCircumference
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
                    ForEach(0..<allPossibleValues.count, id: \.self) { index in
                        let markValue = allPossibleValues[index]
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
                            Text(String(format: "%.0f", markValue))
                                .font(.caption)
                                .foregroundColor(getMarkColor(for: markValue))
                        }
                        .frame(width: thumbWidth)
                        .offset(x: positionForValue(markValue, sliderWidth: sliderWidth) - (thumbWidth / 2))
                        .offset(y: 15)
                    }
                    
                    // Initial Circumference Marker
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .offset(x: positionForValue(initialCircumference, sliderWidth: sliderWidth) - 3)
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
                            
                            if self.circumference != snappedValue {
                                self.circumference = snappedValue
                                self.feedbackGenerator.selectionChanged()
                            }
                        }
                )
            }
            .frame(width: geometry.size.width)
            .onAppear {
                circumference = initialCircumference
                feedbackGenerator.prepare()
            }
        }
        .frame(height: 80)
    }

    // MARK: - Helper Functions

    private func getMarkColor(for mark: Double?) -> Color {
        if let m = mark, m == initialCircumference {
            return .black
        } else if let currentCircumference = circumference, let m = mark, abs(currentCircumference - m) < 0.5 {
            return .black.opacity(0.8)
        }
        return .gray
    }

    private func getThumbText() -> String {
        if let c = circumference { return String(format: "%.1f", c) }
        return "关"
    }

    private func positionForValue(_ value: Double, sliderWidth: CGFloat) -> CGFloat {
        let valueRange = (initialCircumference + rangeSpan) - (initialCircumference - rangeSpan)
        guard valueRange != 0 else { return sliderWidth / 2 }
        
        let ratio = (value - (initialCircumference - rangeSpan)) / valueRange
        let trackWidth = sliderWidth - thumbWidth - (2 * trackPadding)
        let trackStart = (thumbWidth / 2) + trackPadding
        
        return trackStart + (ratio * trackWidth)
    }

    private func valueForPosition(_ x: CGFloat, sliderWidth: CGFloat) -> Double {
        let trackWidth = sliderWidth - thumbWidth - (2 * trackPadding)
        let trackStart = (thumbWidth / 2) + trackPadding
        let relativeX = x - trackStart
        let ratio = max(0, min(1, relativeX / trackWidth))
        
        let valueRange = (initialCircumference + rangeSpan) - (initialCircumference - rangeSpan)
        let value = (initialCircumference - rangeSpan) + ratio * valueRange
        return value
    }

    private func getThumbXOffset(sliderWidth: CGFloat) -> CGFloat {
        let centerX = getThumbCenterX(sliderWidth: sliderWidth)
        return centerX - thumbWidth / 2
    }
    
    private func getThumbCenterX(sliderWidth: CGFloat) -> CGFloat {
        if let c = circumference {
            return positionForValue(c, sliderWidth: sliderWidth)
        }
        return positionForValue(initialCircumference, sliderWidth: sliderWidth)
    }

    private func isHalfMajor(_ value: Double) -> Bool {
        return value.truncatingRemainder(dividingBy: 1.0) == 0.5
    }
}
