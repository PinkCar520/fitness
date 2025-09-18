import SwiftUI

struct FlymeFloatingTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showProfileSheet: Bool
    @Binding var isTabBarCollapsed: Bool // New binding
    @Binding var previousSelectedTab: Int
    @Binding var searchText: String
    var onSearchTap: (() -> Void)?

    private let highlightColor = Color(red: 1.0, green: 0.36, blue: 0.26)
    private let iconNames = ["person", "square.grid.2x2.fill", "checklist", "chart.pie.fill", "magnifyingglass"]
    private let labels = ["Profile", "Documents", "Plan", "Statistics", "Search"]

    @State private var pressedButton: Int? = nil
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var searchFieldFocused: Bool
    @Namespace private var searchAnimation

    var body: some View {
        HStack(spacing: 20) {
            // left button (profile or collapsed tab)
            if keyboardHeight == 0 { // Only show left button if keyboard is not up
                if isTabBarCollapsed { // Show selected tab icon when collapsed
                    let displayIndex = selectedTab == 4 ? previousSelectedTab : selectedTab
                    roundButton(iconName: iconNames[previousSelectedTab], label: labels[previousSelectedTab], isSelected: selectedTab == previousSelectedTab) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isTabBarCollapsed = false
                            selectedTab = displayIndex // Navigate to the selected tab
                            keyboardHeight = 0
                        }
                    }
                } else { // Show profile icon in normal state
                    roundButton(iconName: iconNames[0], label: labels[0], isSelected: selectedTab == 0) {
                        showProfileSheet = true
                        keyboardHeight = 0
                    }
                }
            }

            if !isTabBarCollapsed {
                FlymeDraggableTabButtons(
                    selectedTab: $selectedTab,
                    pressedButton: $pressedButton,
                    iconNames: Array(iconNames[1...3]),
                    accessibilityLabels: Array(labels[1...3]),
                    highlightColor: highlightColor
                )
                .frame(height: 60)
                .transition(.scale.combined(with: .opacity).animation(.spring()))
            }

            HStack(spacing: 0) { // Container for search functionality
                if isTabBarCollapsed { // Expanded search input
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 16)

                    TextField("通过备注搜索...", text: $searchText)
                        .foregroundColor(.primary)
                        .focused($searchFieldFocused)
                        .submitLabel(.search)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)

                    roundButton(iconName: "xmark.circle.fill", label: "Dismiss Search", isSelected: false) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            searchFieldFocused = false
                            isTabBarCollapsed = false
                            keyboardHeight = 0 // Explicitly reset keyboard height
                        }
                    }
//                    .padding(.trailing, 16)
                } else { // Default search button
                    roundButton(iconName: iconNames[4], label: labels[4], isSelected: selectedTab == 4) {
                        onSearchTap?()
                        keyboardHeight = 0
                    }
                    .matchedGeometryEffect(id: "searchBar", in: searchAnimation)
                }
            }
            .background( // Apply background to the entire search container
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white.opacity(0.97))
                    .shadow(color: .black.opacity(0.08), radius: 9, x: 0, y: 3)
            )
            .frame(height: 60) // Apply height to the entire search container
            .padding(.bottom, keyboardHeight)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
//        .padding(.bottom, keyboardHeight) // Apply keyboard padding to the entire tab bar
        .background(Color.clear)
//        .animation(.default, value: isTabBarCollapsed) // Explicit animation for tab bar collapse
//        .animation(.default, value: keyboardHeight) // Explicit animation for keyboard height
        .onAppear(perform: setupKeyboardObservers)
        .onDisappear(perform: removeKeyboardObservers)
    }

    @ViewBuilder
    private func roundButton(iconName: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        ZStack {
            Button {
                pressedButton = 99 // Use a dummy index for animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    pressedButton = nil
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                action() // Execute the passed action
            } label: {
                Image(systemName: iconName) // Use passed iconName
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isSelected ? highlightColor : .gray) // Conditional highlighting
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Circle().fill(highlightColor.opacity(0.18)) : Circle().fill(Color.clear)) // Conditional background
            }
            .scaleEffect(pressedButton == 99 ? 0.81 : 1.0) // Use dummy index for animation
            .accessibilityLabel(label) // Use passed label
        }
        .frame(width: 60, height: 60)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: Circle())
    }

    private var safeBottomInset: CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notif in
            if let info = notif.userInfo,
               let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.22)) {
                    keyboardHeight = frame.height - safeBottomInset
                }
            }
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            withAnimation(.easeOut(duration: 0.22)) { keyboardHeight = 0 }
        }
    }

    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}
