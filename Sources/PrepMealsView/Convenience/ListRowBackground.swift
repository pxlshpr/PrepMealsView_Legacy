import SwiftUI

struct ListRowBackground: View {
    
    @Environment(\.colorScheme) var colorScheme
    @State var separatorColor: Color? = nil
    
    @Binding var color: Color
    @Binding var includeTopPadding: Bool
    @Binding var includeTopSeparator: Bool
    @Binding var includeBottomSeparator: Bool

    init(
        color: Binding<Color> = .constant(.clear),
        includeTopSeparator: Binding<Bool> = .constant(false),
        includeBottomSeparator: Binding<Bool> = .constant(false),
        includeTopPadding: Binding<Bool> = .constant(false)
    ) {
        _color = color
        _includeTopPadding = includeTopPadding
        _includeTopSeparator = includeTopSeparator
        _includeBottomSeparator = includeBottomSeparator
    }
    
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
