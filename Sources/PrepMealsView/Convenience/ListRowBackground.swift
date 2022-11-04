import SwiftUI

struct ListRowBackground: View {
    
    @Environment(\.colorScheme) var colorScheme
    @State var color: Color = .clear
    @State var separatorColor: Color? = nil
    @State var includeTopSeparator: Bool = false
    @State var includeBottomSeparator: Bool = false
    @State var includeTopPadding: Bool = false
    
    var body: some View {
        ZStack {
            color
            VStack(spacing: 0) {
                if includeTopPadding {
                    Color.clear.frame(height: 10)
                }
                if includeTopSeparator {
                    separator
                        .if(separatorColor != nil) { view in
                            view.foregroundColor(separatorColor!)
                        }
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
            .opacity(colorScheme == .light ? 0.225 : 0.225)
    }
}
