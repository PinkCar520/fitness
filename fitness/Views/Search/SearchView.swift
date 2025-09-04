
import SwiftUI

struct SearchView: View {
    @Binding var selectedIndex: Int
    @State private var searchText = ""
    @FocusState private var searchFieldFocused: Bool
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content / search results
            List {
                Text("Sample Result 1 for \(searchText)")
                Text("Sample Result 2 for \(searchText)")
            }
            .listStyle(.plain)
            .opacity(searchText.isEmpty ? 0 : 1)

            if searchText.isEmpty {
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Search for records")
                        .font(.title3)
                        .padding(.top, 8)
                }
                .frame(maxHeight: .infinity)
            }

            // Bottom Search Bar
            BottomSearchBar(searchText: $searchText, isFocused: _searchFieldFocused) {
                // On close, navigate back to the dashboard (index 1)
                selectedIndex = 1
            }
            .padding(.bottom, keyboardHeight > 0 ? keyboardHeight : (safeBottomInset - 8))
        }
        .onAppear(perform: setupKeyboardObservers)
        .onDisappear(perform: removeKeyboardObservers)
        .edgesIgnoringSafeArea(.bottom)
    }

    private var safeBottomInset: CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notif in
            if let info = notif.userInfo,
               let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.22)) {
                    keyboardHeight = frame.height
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
