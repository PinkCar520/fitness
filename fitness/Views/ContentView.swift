import SwiftUI

// Define the KeyboardAdaptive ViewModifier
struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    private var safeBottomInset: CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
    }

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onAppear(perform: setupKeyboardObservers)
            .onDisappear(perform: removeKeyboardObservers)
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

// Extension to make it easier to use
extension View {
    func keyboardAdaptive() -> some View {
        modifier(KeyboardAdaptive())
    }
}

struct ContentView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager

    @State private var selectedIndex = 1
    @State private var showProfileSheet = false
    @State private var showInputSheet = false
    @State private var isTabBarCollapsed: Bool = false
    @State private var previousSelectedTab: Int = 0
    @State private var searchText = ""
    

    var body: some View {
        ZStack {
            TabView(selection: $selectedIndex) {
                ProfileView().tag(0)
                SummaryDashboardView(showInputSheet: $showInputSheet).tag(1)
                PlanView().tag(2)
                StatsView().tag(3)
                SearchView(selectedIndex: $selectedIndex, searchText: $searchText).tag(4)
            }
            .onAppear { UITabBar.appearance().isHidden = true }

            VStack {
                Spacer()
                
                FlymeFloatingTabBar(
                    selectedTab: $selectedIndex,
                    showProfileSheet: $showProfileSheet,
                    isTabBarCollapsed: $isTabBarCollapsed,
                    previousSelectedTab: $previousSelectedTab,
                    searchText: $searchText,
                    onSearchTap: {
                        if selectedIndex != 4 {
                            previousSelectedTab = selectedIndex
                        }
                        isTabBarCollapsed.toggle()
                        selectedIndex = 4
                    }
                )
                .padding(.bottom, 5)
                }
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showProfileSheet) {
            ProfilePopupView()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showInputSheet) { InputSheetView() }
        .keyboardAdaptive() // Apply the new modifier here
    }
}
