import SwiftUI

struct BottomSearchBar: View {
    @Binding var searchText: String
    @FocusState var isFocused: Bool
    var onClose: () -> Void

    @State private var appearOffset: CGFloat = UIScreen.main.bounds.width

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 0) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 16)

                TextField("Search...", text: $searchText)
                    .padding(16)
                    .focused($isFocused)
                    .submitLabel(.search)
            }
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 32))
            
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .padding(16)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 32))
                    
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .offset(x: appearOffset)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.45)) {
                appearOffset = 0
            }
        }
        .onDisappear {
            appearOffset = UIScreen.main.bounds.width
        }
    }
}