import SwiftUI
import UIKit

struct TargetWeightSliderConfiguration {
    var rangeSpan: Double = 20
    var minimumWeight: Double = 40
    var maximumWeight: Double = 150
    var step: Double = 1
    var majorTickInterval: Int = 10
    var halfTickInterval: Int = 5
    var containerInset: CGFloat = 2
    var trackPadding: CGFloat = 5
    var trackHeight: CGFloat = 60
    var thumbWidth: CGFloat = 50
    var backgroundColor: Color = Color.gray.opacity(0.2)
    var minorTickColor: Color = Color.gray.opacity(0.4)
    var halfTickColor: Color = Color.gray.opacity(0.6)
    var majorTickColor: Color = Color.gray.opacity(0.8)
    var initialMarkerColor: Color = .blue
    var thumbColor: Color = .white
    var thumbTextColor: Color = .black
    var labelBaseColor: Color = .gray
    var labelHighlightColor: Color = .black
    var labelAdjacentHighlightColor: Color = Color.black.opacity(0.8)

    static let planSetup = TargetWeightSliderConfiguration()
}

struct TargetWeightSlider: View {
    @Binding var weight: Double
    private let baselineWeight: Double
    private let configuration: TargetWeightSliderConfiguration
    private let feedbackGenerator = UISelectionFeedbackGenerator()
    
    // 预计算的刻度值
    private let ticks: (major: [Double], half: [Double], minor: [Double])
    
    @State private var windowCenter: Double
    @State private var isDragging = false
    @State private var valuePulseScale: CGFloat = 1
    @State private var valuePulseOpacity: Double = 0
    
    init(
        weight: Binding<Double>,
        baselineWeight: Double,
        configuration: TargetWeightSliderConfiguration = .planSetup
    ) {
        self._weight = weight
        self.baselineWeight = baselineWeight
        self.configuration = configuration
        
        // 预计算所有刻度
        self.ticks = Self.calculateTicks(config: configuration)
        
        // 计算初始窗口中心
        let span = min(configuration.rangeSpan, (configuration.maximumWeight - configuration.minimumWeight) / 2)
        let minCenter = configuration.minimumWeight + span
        let maxCenter = configuration.maximumWeight - span
        self._windowCenter = State(initialValue: baselineWeight.clamped(to: minCenter...maxCenter))
    }
    
    // 当前可见范围
    private var visibleRange: ClosedRange<Double> {
        let span = min(configuration.rangeSpan, (configuration.maximumWeight - configuration.minimumWeight) / 2)
        let lower = max(configuration.minimumWeight, windowCenter - span)
        let upper = min(configuration.maximumWeight, windowCenter + span)
        return lower...upper
    }
    
    // 限制后的权重值
    private var clampedWeight: Double {
        weight.clamped(to: visibleRange)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let sliderWidth = geometry.size.width - 2 * configuration.containerInset
            
            ZStack(alignment: .leading) {
                // 背景轨道
                RoundedRectangle(cornerRadius: 30)
                    .fill(configuration.backgroundColor)
                    .frame(width: sliderWidth, height: configuration.trackHeight)
                
                // 刻度线（合并渲染逻辑）
                tickLayer(ticks.minor, configuration.minorTickColor, 10, -4, 0.8, sliderWidth)
                tickLayer(ticks.half, configuration.halfTickColor, 14, -2, 1, sliderWidth)
                tickLayer(ticks.major, configuration.majorTickColor, 18, 0, 1.2, sliderWidth)
                
                // 主刻度标签
                ForEach(ticks.major, id: \.self) { value in
                    Text("\(Int(value))")
                        .font(.caption)
                        .foregroundColor(labelColor(for: value))
                        .frame(width: configuration.thumbWidth)
                        .offset(x: xPosition(for: value, width: sliderWidth) - (configuration.thumbWidth / 2))
                        .offset(y: configuration.trackHeight / 2 + 10)
                        .opacity(isVisible(value) ? 1 : 0)
                }
                
                // 基线标记
                Circle()
                    .fill(configuration.initialMarkerColor)
                    .frame(width: 6, height: 6)
                    .offset(x: xPosition(for: baselineWeight, width: sliderWidth) - 3)
                    .offset(y: -10)
                
                // 拖动滑块
                Circle()
                    .fill(configuration.thumbColor)
                    .frame(width: configuration.thumbWidth, height: configuration.thumbWidth)
                    .overlay(
                        Text("\(Int(clampedWeight))")
                            .font(.headline)
                            .foregroundColor(configuration.thumbTextColor)
                            .contentTransition(.numericText(countsDown: false))
                            .scaleEffect(valuePulseScale)
                            .shadow(color: Color.blue.opacity(valuePulseOpacity), radius: 8)
                    )
                    .offset(x: xPosition(for: clampedWeight, width: sliderWidth) - configuration.thumbWidth / 2)
            }
            .gesture(dragGesture(sliderWidth: sliderWidth))
            .onAppear {
                updateWindowCenter(to: clampedWeight, factor: 1, animated: false)
                feedbackGenerator.prepare()
            }
            .onChange(of: weight) { oldValue, newValue in
                guard !isDragging else { return }
                let clamped = newValue.clamped(to: visibleRange)
                if clamped != newValue {
                    weight = clamped
                }
                updateWindowCenter(to: clamped, factor: 1, animated: true)
            }
        }
        .frame(height: configuration.trackHeight + 40)
    }
    
    // MARK: - 刻度层渲染
    private func tickLayer(_ values: [Double], _ color: Color, _ height: CGFloat,
                          _ yOffset: CGFloat, _ lineWidth: CGFloat, _ sliderWidth: CGFloat) -> some View {
        ForEach(values, id: \.self) { value in
            Rectangle()
                .fill(color)
                .frame(width: lineWidth, height: height)
                .offset(x: xPosition(for: value, width: sliderWidth) - (lineWidth / 2))
                .offset(y: yOffset)
                .opacity(isVisible(value) ? 1 : 0)
        }
    }
    
    // MARK: - 拖动手势
    private func dragGesture(sliderWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                isDragging = true
                let newValue = valueAt(x: gesture.location.x, sliderWidth: sliderWidth)
                    .snapped(to: configuration.step)
                    .clamped(to: visibleRange)
                
                if abs(weight - newValue) >= configuration.step / 2 {
                    feedbackGenerator.selectionChanged()
                }
                
                Transaction(animation: nil).perform {
                    weight = newValue
                    updateWindowCenter(to: newValue, factor: 0.3, animated: true)
                }
            }
            .onEnded { _ in
                isDragging = false
                updateWindowCenter(to: clampedWeight, factor: 1, animated: true)
                pulseValue()
            }
    }
    
    // MARK: - 辅助方法
    private func xPosition(for value: Double, width: CGFloat) -> CGFloat {
        let range = visibleRange.upperBound - visibleRange.lowerBound
        guard range > 0 else { return width / 2 }
        
        let ratio = (value.clamped(to: visibleRange) - visibleRange.lowerBound) / range
        let trackWidth = width - configuration.thumbWidth - 2 * configuration.trackPadding
        return configuration.thumbWidth / 2 + configuration.trackPadding + CGFloat(ratio) * trackWidth
    }
    
    private func valueAt(x: CGFloat, sliderWidth: CGFloat) -> Double {
        let trackWidth = sliderWidth - configuration.thumbWidth - 2 * configuration.trackPadding
        let trackStart = configuration.thumbWidth / 2 + configuration.trackPadding
        let ratio = ((x - trackStart) / trackWidth).clamped(to: 0...1)
        return visibleRange.lowerBound + Double(ratio) * (visibleRange.upperBound - visibleRange.lowerBound)
    }
    
    private func labelColor(for value: Double) -> Color {
        if abs(value - baselineWeight) < 0.5 { return configuration.labelHighlightColor }
        if abs(clampedWeight - value) < configuration.step / 2 { return configuration.labelAdjacentHighlightColor }
        return configuration.labelBaseColor
    }
    
    private func isVisible(_ value: Double) -> Bool {
        value >= visibleRange.lowerBound - configuration.step &&
        value <= visibleRange.upperBound + configuration.step
    }
    
    private func updateWindowCenter(to value: Double, factor: Double, animated: Bool) {
        let span = min(configuration.rangeSpan, (configuration.maximumWeight - configuration.minimumWeight) / 2)
        let allowedRange = (configuration.minimumWeight + span)...(configuration.maximumWeight - span)
        let ideal = value.clamped(to: allowedRange)
        let next = (windowCenter + (ideal - windowCenter) * factor).clamped(to: allowedRange)
        
        if animated {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                windowCenter = next
            }
        } else {
            windowCenter = next
        }
    }
    
    private func pulseValue() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
            valuePulseScale = 1.04
            valuePulseOpacity = 0.35
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                valuePulseScale = 1
                valuePulseOpacity = 0
            }
        }
    }
    
    // MARK: - 静态方法
    private static func calculateTicks(config: TargetWeightSliderConfiguration) -> (major: [Double], half: [Double], minor: [Double]) {
        let values = stride(from: config.minimumWeight, through: config.maximumWeight, by: config.step)
            .map { ($0 * 10).rounded() / 10 }
        
        let major = values.filter { Int($0.rounded()) % config.majorTickInterval == 0 }
        let majorSet = Set(major.map { Int($0.rounded()) })
        
        let half = values.filter {
            let rounded = Int($0.rounded())
            return rounded % config.halfTickInterval == 0 && !majorSet.contains(rounded)
        }
        let halfSet = Set(half.map { Int($0.rounded()) })
        
        let minor = values.filter {
            let rounded = Int($0.rounded())
            return !majorSet.contains(rounded) && !halfSet.contains(rounded)
        }
        
        return (major, half, minor)
    }
}

// MARK: - 扩展
extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
    
    func snapped(to step: Double) -> Double {
        (self / step).rounded() * step
    }
}

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

extension Transaction {
    func perform(_ action: () -> Void) {
        withTransaction(self, action)
    }
}
