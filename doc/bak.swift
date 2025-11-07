// import SwiftUI
// import UIKit
//
// struct TargetWeightSliderConfiguration {
//     var rangeSpan: Double = 20
//     var minimumWeight: Double = 40
//     var maximumWeight: Double = 150
//     var step: Double = 1
//     var majorTickInterval: Int = 10
//     var halfTickInterval: Int = 5
//     var containerInset: CGFloat = 2
//     var trackPadding: CGFloat = 5
//     var trackHeight: CGFloat = 60
//     var thumbWidth: CGFloat = 50
//     var backgroundColor: Color = Color.gray.opacity(0.2)
//     var minorTickColor: Color = Color.gray.opacity(0.4)
//     var halfTickColor: Color = Color.gray.opacity(0.6)
//     var majorTickColor: Color = Color.gray.opacity(0.8)
//     var initialMarkerColor: Color = .blue
//     var thumbColor: Color = .white
//     var thumbTextColor: Color = .black
//     var labelBaseColor: Color = .gray
//     var labelHighlightColor: Color = .black
//     var labelAdjacentHighlightColor: Color = Color.black.opacity(0.8)
//
//     static let planSetup = TargetWeightSliderConfiguration()
// }
//
// struct TargetWeightSlider: View {
//     @Binding var weight: Double
//     private let baselineWeight: Double
//     private let configuration: TargetWeightSliderConfiguration
//     private let feedbackGenerator = UISelectionFeedbackGenerator()
//     private let windowCenterFollowFactor: Double = 0.3
//     private let majorTickValues: [Double]
//     private let halfTickValues: [Double]
//     private let minorTickValues: [Double]
//     private var tickDescriptors: [TickDescriptor] {
//         [
//             (minorTickValues, configuration.minorTickColor, 10, -4, 0.8),
//             (halfTickValues, configuration.halfTickColor, 14, -2, 1),
//             (majorTickValues, configuration.majorTickColor, 18, 0, 1.2)
//         ]
//     }
//
//     @State private var windowCenter: Double
//     @State private var isDragging = false
//     @State private var valuePulseScale: CGFloat = 1
//     @State private var valuePulseOpacity: Double = 0
//
//     init(
//         weight: Binding<Double>,
//         baselineWeight: Double,
//         configuration: TargetWeightSliderConfiguration = .planSetup
//     ) {
//         self._weight = weight
//         self.baselineWeight = baselineWeight
//         self.configuration = configuration
//         let tickCollections = TargetWeightSlider.makeTickCollections(configuration: configuration)
//         self.majorTickValues = tickCollections.major
//         self.halfTickValues = tickCollections.half
//         self.minorTickValues = tickCollections.minor
//
//         let initialCenter = TargetWeightSlider.initialWindowCenter(
//             baselineWeight: baselineWeight,
//             configuration: configuration
//         )
//         self._windowCenter = State(initialValue: initialCenter)
//         self._isDragging = State(initialValue: false)
//     }
//
//     private var weightBounds: ClosedRange<Double> {
//         let minimum = sliderMinimum
//         let maximum = sliderMaximum
//         guard maximum > minimum else { return minimum...minimum }
//
//         let halfSpan = min(configuration.rangeSpan, (maximum - minimum) / 2)
//         guard halfSpan > 0 else {
//             let center = (minimum + maximum) / 2
//             return center...center
//         }
//
//         let lower = max(minimum, currentWindowCenter - halfSpan)
//         let upper = min(maximum, currentWindowCenter + halfSpan)
//         return lower...max(lower, upper)
//     }
//
//     var body: some View {
//         GeometryReader { geometry in
//             let sliderWidth = geometry.size.width - 2 * configuration.containerInset
//
//             ZStack(alignment: .leading) {
//                 RoundedRectangle(cornerRadius: 30)
//                     .fill(configuration.backgroundColor)
//                     .frame(width: sliderWidth, height: configuration.trackHeight)
//
//                 let layers = tickDescriptors
//                 ForEach(Array(layers.enumerated()), id: \.offset) { _, layer in
//                     ForEach(layer.values, id: \.self) { markValue in
//                         Rectangle()
//                             .fill(layer.color)
//                             .frame(width: layer.lineWidth, height: layer.height)
//                             .offset(x: position(for: markValue, sliderWidth: sliderWidth) - (layer.lineWidth / 2))
//                             .offset(y: layer.yOffset)
//                             .opacity(visibilityOpacity(for: markValue, visibleBounds: weightBounds))
//                     }
//                 }
//
//                 ForEach(majorTickValues, id: \.self) { markValue in
//                     VStack(spacing: 2) {
//                         Text(labelText(for: markValue))
//                             .font(.caption)
//                             .foregroundColor(labelColor(for: markValue))
//                     }
//                     .frame(width: configuration.thumbWidth)
//                     .offset(x: position(for: markValue, sliderWidth: sliderWidth) - (configuration.thumbWidth / 2))
//                     .offset(y: configuration.trackHeight / 2 + 10)
//                     .opacity(visibilityOpacity(for: markValue, visibleBounds: weightBounds))
//                 }
//
//                 Circle()
//                     .fill(configuration.initialMarkerColor)
//                     .frame(width: 6, height: 6)
//                     .offset(x: position(for: baselineWeight, sliderWidth: sliderWidth) - 3)
//                     .offset(y: -10)
//
//                 Circle()
//                     .fill(configuration.thumbColor)
//                     .frame(width: configuration.thumbWidth, height: configuration.thumbWidth)
//                     .overlay(
//                         Text(labelText(for: clampedWeight))
//                             .font(.headline)
//                             .foregroundColor(configuration.thumbTextColor)
//                             .contentTransition(.numericText(countsDown: false))
//                             .scaleEffect(valuePulseScale)
//                             .shadow(color: Color.blue.opacity(valuePulseOpacity), radius: 8, x: 0, y: 0)
//                     )
//                     .offset(x: thumbOffset(sliderWidth: sliderWidth))
//             }
//             .frame(width: sliderWidth)
//             .highPriorityGesture(
//                 DragGesture(minimumDistance: 0)
//                     .onChanged { gesture in
//                         if !isDragging {
//                             isDragging = true
//                         }
//
//                         let trackStart = (configuration.thumbWidth / 2) + configuration.trackPadding
//                         let trackEnd = sliderWidth - (configuration.thumbWidth / 2) - configuration.trackPadding
//                         let clampedX = max(trackStart, min(gesture.location.x, trackEnd))
//
//                         let proposed = value(for: clampedX, sliderWidth: sliderWidth)
//                         let snapped = snapToStep(proposed, step: configuration.step)
//                         let clampedValue = min(max(snapped, weightBounds.lowerBound), weightBounds.upperBound)
//
//                         performWithoutAnimation {
//                             if abs(weight - clampedValue) >= configuration.step / 2 {
//                                 feedbackGenerator.selectionChanged()
//                             }
//
//                             weight = clampedValue
//
//                             updateWindowCenter(
//                                 for: clampedValue,
//                                 immediate: false,
//                                 animation: .interactiveSpring(
//                                     response: 0.25,
//                                     dampingFraction: 0.85
//                                 ),
//                                 lerpFactor: windowCenterFollowFactor
//                             )
//                         }
//                     }
//                     .onEnded { _ in
//                         isDragging = false
//                         updateWindowCenter(
//                             for: clampedWeight,
//                             immediate: false,
//                             animation: .spring(response: 0.35, dampingFraction: 0.85),
//                             lerpFactor: 1
//                         )
//                         pulseValue()
//         }
//             )
//             .onAppear {
//                 performWithoutAnimation {
//                     updateWindowCenter(for: clampedWeight, immediate: true, animation: nil)
//                 }
//                 feedbackGenerator.prepare()
//             }
//         }
//         .frame(height: configuration.trackHeight + 40)
//         .onChange(of: weight) { newValue in
//             guard !isDragging else { return }
//
//             let sanitizedValue = clampedWeightValue(newValue)
//             if sanitizedValue != newValue {
//                 performWithoutAnimation {
//                     weight = sanitizedValue
//                 }
//             }
//
//             updateWindowCenter(
//                 for: sanitizedValue,
//                 immediate: false,
//                 animation: .easeOut(duration: 0.2)
//             )
//         }
//     }
//
//     private func labelText(for value: Double) -> String {
//         String(format: "%.0f", value)
//     }
//
//     private func labelColor(for mark: Double) -> Color {
//         if abs(mark - baselineWeight) < 0.5 {
//             return configuration.labelHighlightColor
//         }
//         if abs(clampedWeight - mark) < max(configuration.step, 1) * 0.5 {
//             return configuration.labelAdjacentHighlightColor
//         }
//         return configuration.labelBaseColor
//     }
//
//     private func snapToStep(_ value: Double, step: Double) -> Double {
//         let quotient = (value / step).rounded()
//         return quotient * step
//     }
//
//     private func position(for value: Double, sliderWidth: CGFloat) -> CGFloat {
//         let bounds = weightBounds
//         let range = bounds.upperBound - bounds.lowerBound
//         guard range > 0 else { return sliderWidth / 2 }
//
//         let value = clampedWeightValue(value)
//         let ratio = (value - bounds.lowerBound) / range
//         let trackWidth = sliderWidth - configuration.thumbWidth - (2 * configuration.trackPadding)
//         let trackStart = (configuration.thumbWidth / 2) + configuration.trackPadding
//
//         return trackStart + CGFloat(ratio) * trackWidth
//     }
//
//     private func value(for xPosition: CGFloat, sliderWidth: CGFloat) -> Double {
//         let bounds = weightBounds
//         let trackWidth = sliderWidth - configuration.thumbWidth - (2 * configuration.trackPadding)
//         let trackStart = (configuration.thumbWidth / 2) + configuration.trackPadding
//         let relativeX = Double(xPosition - trackStart)
//         let ratio = max(0, min(1, relativeX / Double(trackWidth)))
//         return bounds.lowerBound + ratio * (bounds.upperBound - bounds.lowerBound)
//     }
//
//     private func thumbOffset(sliderWidth: CGFloat) -> CGFloat {
//         position(for: clampedWeight, sliderWidth: sliderWidth) - configuration.thumbWidth / 2
//     }
//
//     private var sliderMinimum: Double {
//         configuration.minimumWeight
//     }
//
//     private var sliderMaximum: Double {
//         max(configuration.maximumWeight, sliderMinimum)
//     }
//
//     private var sliderMidpoint: Double {
//         (sliderMinimum + sliderMaximum) / 2
//     }
//
//     private var allowedCenterRange: ClosedRange<Double> {
//         let span = min(configuration.rangeSpan, (sliderMaximum - sliderMinimum) / 2)
//         guard span > 0 else { return sliderMidpoint...sliderMidpoint }
//         let minCenter = sliderMinimum + span
//         let maxCenter = sliderMaximum - span
//         return minCenter <= maxCenter ? minCenter...maxCenter : sliderMidpoint...sliderMidpoint
//     }
//
//     private var currentWindowCenter: Double {
//         clampedCenter(windowCenter)
//     }
//
//     private var clampedWeight: Double {
//         clampedWeightValue(weight)
//     }
//
//     private func clampedCenter(_ center: Double) -> Double {
//         clamp(center, to: allowedCenterRange)
//     }
//
//     private func idealCenter(for weight: Double) -> Double {
//         clampedCenter(weight)
//     }
//
//     private func updateWindowCenter(
//         for newWeight: Double,
//         immediate: Bool,
//         animation: Animation?,
//         lerpFactor: Double? = nil
//     ) {
//         let ideal = idealCenter(for: newWeight)
//
//         let factor = clamp(lerpFactor ?? windowCenterFollowFactor, to: 0...1)
//         let nextCenter: Double
//
//         if immediate {
//             nextCenter = ideal
//         } else {
//             let delta = ideal - windowCenter
//             nextCenter = clampedCenter(windowCenter + delta * factor)
//         }
//
//         if let animation {
//             withAnimation(animation) {
//                 windowCenter = nextCenter
//             }
//         } else {
//             windowCenter = nextCenter
//         }
//     }
//
//     private func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
//         min(max(value, range.lowerBound), range.upperBound)
//     }
//
//     private func clampedWeightValue(_ value: Double) -> Double {
//         clamp(value, to: weightBounds)
//     }
//
//     private func pulseValue() {
//         let animation = Animation.interactiveSpring(response: 0.2, dampingFraction: 0.75)
//         withAnimation(animation) {
//             valuePulseScale = 1.04
//             valuePulseOpacity = 0.35
//         }
//
//         DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
//             withAnimation(animation) {
//                 valuePulseScale = 1
//                 valuePulseOpacity = 0
//             }
//         }
//     }
//
//     private func visibilityOpacity(for value: Double, visibleBounds: ClosedRange<Double>) -> Double {
//         isValueVisible(value, visibleBounds: visibleBounds) ? 1 : 0
//     }
//
//     private func isValueVisible(_ value: Double, visibleBounds: ClosedRange<Double>) -> Bool {
//         let margin = max(configuration.step, 1)
//         return value >= visibleBounds.lowerBound - margin && value <= visibleBounds.upperBound + margin
//     }
//
//     private func performWithoutAnimation(_ action: () -> Void) {
//         var transaction = Transaction()
//         transaction.disablesAnimations = true
//         withTransaction(transaction) {
//             action()
//         }
//     }
//
//     private typealias TickDescriptor = (values: [Double], color: Color, height: CGFloat, yOffset: CGFloat, lineWidth: CGFloat)
//
//     private static func makeTickCollections(
//         configuration: TargetWeightSliderConfiguration
//     ) -> (major: [Double], half: [Double], minor: [Double]) {
//         let minimum = configuration.minimumWeight
//         let maximum = max(configuration.maximumWeight, minimum)
//         let step = max(configuration.step, 0.1)
//
//         var values = stride(from: minimum, through: maximum, by: step)
//             .map { round($0 * 10) / 10 }
//
//         if let last = values.last, (maximum - last) > 0.001 {
//             values.append(maximum)
//         }
//
//         let major = values.filter { isValue($0, multipleOf: configuration.majorTickInterval) }
//         let majorSet = Set(major.map { Int(round($0)) })
//         let half = values.filter {
//             configuration.halfTickInterval > 0 &&
//             isValue($0, multipleOf: configuration.halfTickInterval) &&
//             !majorSet.contains(Int(round($0)))
//         }
//         let halfSet = Set(half.map { Int(round($0)) })
//         let minor = values.filter {
//             let rounded = Int(round($0))
//             return !majorSet.contains(rounded) && !halfSet.contains(rounded)
//         }
//
//         return (major: major, half: half, minor: minor)
//     }
//
//     private static func isValue(_ value: Double, multipleOf interval: Int) -> Bool {
//         let divisor = max(interval, 1)
//         guard divisor > 0 else { return false }
//         let rounded = Int(round(value))
//         return rounded % divisor == 0
//     }
//
//     private static func initialWindowCenter(
//         baselineWeight: Double,
//         configuration: TargetWeightSliderConfiguration
//     ) -> Double {
//         let minimum = configuration.minimumWeight
//         let maximum = max(configuration.maximumWeight, minimum)
//         let maxHalfSpan = (maximum - minimum) / 2
//         let desiredHalfSpan = max(0, min(configuration.rangeSpan, maxHalfSpan))
//
//         guard desiredHalfSpan > 0 else {
//             return (minimum + maximum) / 2
//         }
//
//         let minCenter = minimum + desiredHalfSpan
//         let maxCenter = maximum - desiredHalfSpan
//
//         if minCenter > maxCenter {
//             return (minimum + maximum) / 2
//         }
//
//         return min(max(baselineWeight, minCenter), maxCenter)
//     }
// }
