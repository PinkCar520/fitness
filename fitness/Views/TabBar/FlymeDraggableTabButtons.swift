
import SwiftUI

struct FlymeDraggableTabButtons: View {
    @Binding var selectedTab: Int
    @Binding var pressedButton: Int?
    let iconNames: [String]
    let accessibilityLabels: [String]
    let highlightColor: Color

    @State private var dragHighlightIndex: Int? = nil
    private let buttonCount = 3
    private let buttonSize: CGFloat = 44
    private let buttonSpacing: CGFloat = 20
    private let capsulePadding: CGFloat = 10

    var body: some View {
        ZStack {
            Capsule()
                .fill(.thinMaterial)
            GeometryReader { geo in
                HStack(spacing: buttonSpacing) {
                    ForEach(0..<buttonCount, id: \.self) { idx in
                        let globalIdx = idx + 1
                        let isSelected = selectedTab == globalIdx
                        let isHighlighted = dragHighlightIndex == idx
                        Image(systemName: iconNames[idx])
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(isHighlighted || isSelected ? highlightColor : .gray)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(Circle().fill((isHighlighted || isSelected) ? highlightColor.opacity(0.12) : .clear))
                            .scaleEffect(pressedButton == globalIdx ? 0.81 : (isHighlighted ? 1.18 : 1.0))
                            .offset(y: isHighlighted ? -16 : 0)
                            .accessibilityLabel(accessibilityLabels[idx])
                            .onTapGesture {
                                withAnimation(.spring(response: 0.26, dampingFraction: 0.55)) { pressedButton = globalIdx }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                    selectedTab = globalIdx
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) { pressedButton = nil }
                                }
                            }
                    }
                }
                .padding(.horizontal, capsulePadding)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { value in
                            let local = value.location
                            let totalButtonWidth = CGFloat(buttonCount) * buttonSize + CGFloat(buttonCount - 1) * buttonSpacing
                            let hStart = (geo.size.width - totalButtonWidth) / 2
                            var found: Int? = nil
                            for idx in 0..<buttonCount {
                                let centerX = hStart + CGFloat(idx) * (buttonSize + buttonSpacing) + buttonSize/2
                                if abs(local.x - centerX) < buttonSize/1.15 { found = idx; break }
                            }
                            if dragHighlightIndex != found {
                                if found != nil {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                                withAnimation(.interpolatingSpring(stiffness: 250, damping: 18)) { dragHighlightIndex = found }
                            }
                        }
                        .onEnded { _ in
                            if let idx = dragHighlightIndex {
                                let globalIdx = idx + 1
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { pressedButton = globalIdx }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                                    selectedTab = globalIdx
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) { pressedButton = nil }
                                }
                            }
                            withAnimation(.interpolatingSpring(stiffness: 250, damping: 18)) { dragHighlightIndex = nil }
                        }
                )
            }
            .frame(height: buttonSize)
        }
    }
}
