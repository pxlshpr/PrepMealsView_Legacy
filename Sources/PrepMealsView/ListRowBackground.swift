import SwiftUI

struct ListRowBackground: View {
    
    @State var color: Color = .clear
    @State var includeTopSeparator: Bool = false
    @State var includeBottomSeparator: Bool = false
    
    var body: some View {
        ZStack {
            color
            VStack(spacing: 0) {
                if includeTopSeparator {
                    separator
                }
                Spacer()
                if includeBottomSeparator {
                    separator
                }
            }
        }
    }
    
    var separator: some View {
        Rectangle()
            .frame(height: 0.18)
            .background(Color(.separator))
            .opacity(0.225)
    }
}

