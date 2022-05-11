import SwiftUI

public struct StaggeredGrid<Elements, Content>: View where Elements: RandomAccessCollection, Elements.Element: Identifiable, Content: View {
    
    public var containerWidth: CGFloat
    public var data: Elements
    public var numberOfColumns: Int
    public var content: (Elements.Element) -> Content
    
    public var horizontalSpacing: CGFloat = 16.0
    public var verticalSpacing: CGFloat = 16.0
    public var sectionInsets: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    
    @State private var sizes: [Elements.Element.ID: CGSize] = [:]
    
    public init(containerWidth: CGFloat, data: Elements, numberOfColumns: Int = 2, content: @escaping (Elements.Element) -> Content ) {
        self.containerWidth = containerWidth
        self.data = data
        self.numberOfColumns = numberOfColumns
        self.content = content
    }
    
    private func calculateLayout(containerWidth: CGFloat) -> (offsets: [Elements.Element.ID: CGSize], contentHeight: CGFloat, columnWidth: CGFloat) {
        var state = StaggeredLayout(
            containerWidth: containerWidth,
            numberOfColumns: numberOfColumns,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            sectionInset: sectionInsets)
        var result: [Elements.Element.ID: CGSize] = [:]
        for element in data {
            let rect = state.add(element: sizes[element.id] ?? .zero)
            result[element.id] = CGSize(width: rect.origin.x, height: rect.origin.y)
        }
        return (result, state.maxY, state.columnWidth)
    }
    
    
    public var body: some View {
        let layout = calculateLayout(containerWidth: containerWidth)
 
        return VStack {
            ZStack(alignment: .topLeading) {
                
                ForEach(self.data) {
                    PropagateSize(
                        content: self.content($0),
                        id: $0.id,
                        columnWidth: layout.columnWidth)
                        .offset(layout.offsets[$0.id] ?? .zero)
                }
                .animation(.default)
                
                Color.clear
                    .frame(
                        width: containerWidth,
                        height: layout.contentHeight)
            }
            .onPreferenceChange(StaggeredViewSizeKey.self) {
                self.sizes = $0
            }
            .frame(
                width: containerWidth,
                height: layout.contentHeight)
        }
    }
}

private struct StaggeredLayout {
    
    let containerWidth: CGFloat
    let numberOfColumns: Int
    let columnWidth: CGFloat
    let xOffsets: [CGFloat]
    var maxY: CGFloat = 0
    private var currentColumn = 0
    private var yOffsets = [CGFloat]()

    private let sectionInset: EdgeInsets
    private let horizontalSpacing: CGFloat
    private let verticalSpacing: CGFloat
    
    init(containerWidth: CGFloat, numberOfColumns: Int = 2, horizontalSpacing: CGFloat = 2, verticalSpacing: CGFloat = 2, sectionInset: EdgeInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)) {
        assert(numberOfColumns > 0, "Number of columns minimal is 1")
        
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.sectionInset = sectionInset
        self.containerWidth = containerWidth
        self.numberOfColumns = numberOfColumns
        
        let totalHorizontalSpacingWidth = CGFloat(numberOfColumns - 1) * horizontalSpacing
        let insetsWidth = sectionInset.leading + sectionInset.trailing
        columnWidth = (containerWidth - totalHorizontalSpacingWidth - insetsWidth) / CGFloat(numberOfColumns)
        var xOffsets = [CGFloat]()
        var x: CGFloat = 0
        
        for col in 0..<numberOfColumns {
            x = sectionInset.leading + (CGFloat(col) * (columnWidth + horizontalSpacing))
            xOffsets.append(x)
        }
        
        self.xOffsets = xOffsets
        self.yOffsets = .init(repeating: sectionInset.top, count: numberOfColumns)
    }
    
    mutating func add(element size: CGSize) -> CGRect {
        if currentColumn > numberOfColumns - 1 {
            currentColumn = 0
        }
        
        defer {
            currentColumn += 1
        }
        
        let y = yOffsets[currentColumn]
        yOffsets[currentColumn] = y + size.height + verticalSpacing
        maxY = max(maxY, yOffsets[currentColumn])
        return CGRect(x: xOffsets[currentColumn], y: y, width: columnWidth, height: size.height)
    }
    
    var size: CGSize {
        return CGSize(width: containerWidth, height: maxY + sectionInset.bottom)
    }
}

private struct PropagateSize<V: View, ID: Hashable>: View {
    
    var content: V
    var id: ID
    var columnWidth: CGFloat
    
    var body: some View {
        content
            .frame(width: columnWidth)
            .background(GeometryReader { proxy in
                self.backgroundContent(proxy: proxy)
            })
            .clipped()
    }
    
    private func backgroundContent(proxy: GeometryProxy) -> some View {
        return Color
            .clear
            .preference(key: StaggeredViewSizeKey.self, value: [self.id: proxy.size])
    }
}

private struct StaggeredViewSizeKey<ID: Hashable>: PreferenceKey {
    typealias Value = [ID: CGSize]
    
    static var defaultValue: [ID: CGSize] { [:] }
    static func reduce(value: inout [ID: CGSize], nextValue: () -> [ID: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: {$1})
    }
    
}
