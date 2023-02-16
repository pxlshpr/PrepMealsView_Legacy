import SwiftUI

struct DiarySeparatorLineColor {
    static var light = "B3B3B6"
    static var dark = "424242"
}

struct DiaryDividerLineColor {
    static var light = "D6D6D7"
    static var dark = "3a3a3a"  //"333333"
}

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
        Color(hex: colorScheme == .light ? DiarySeparatorLineColor.light : DiarySeparatorLineColor.dark)
            .frame(height: 0.18)
    }
}
