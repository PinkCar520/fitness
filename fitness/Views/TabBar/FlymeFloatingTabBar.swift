import SwiftUI

struct FlymeFloatingTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showProfileSheet: Bool
    var onSearchTap: (() -> Void)?

    private let highlightColor = Color(red: 1.0, green: 0.36, blue: 0.26)
    private let iconNames = ["person", "square.grid.2x2.fill", "checklist", "chart.pie.fill", "magnifyingglass"]
    private let labels = ["Profile", "Documents", "Plan", "Statistics", "Search"]

    @State private var pressedButton: Int? = nil

    var body: some View {
        HStack(spacing: 20) {
            // left avatar
            roundButton(index: 0) {
                showProfileSheet = true
            }

            FlymeDraggableTabButtons(
                selectedTab: $selectedTab,
                pressedButton: $pressedButton,
                iconNames: Array(iconNames[1...3]),
                accessibilityLabels: Array(labels[1...3]),
                highlightColor: highlightColor
            )
            .frame(height: 60)

            // right search
            roundButton(index: 4) {
                onSearchTap?()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.clear)
    }

    @ViewBuilder
    private func roundButton(index: Int, action: @escaping () -> Void) -> some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.97))
                .shadow(color: .black.opacity(0.08), radius: 9, x: 0, y: 3)
            Button {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.6)) { pressedButton = index }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) { pressedButton = nil }
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if index == 0 { showProfileSheet = true }
                else { action() }
            } label: {
                Image(systemName: iconNames[index])
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(pressedButton == index || selectedTab == index ? highlightColor : .gray)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill((pressedButton == index || selectedTab == index) ? highlightColor.opacity(0.18) : Color.clear))
            }
            .scaleEffect(pressedButton == index ? 0.81 : 1.0)
            .accessibilityLabel(labels[index])
        }
        .frame(width: 60, height: 60)
    }
}
