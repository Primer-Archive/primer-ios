import SwiftUI

struct PagerView<Content: View>: View {
    let pageCount: Int
    @State var currentIndex: Int = 0
    let content: Content

    @GestureState private var translation: CGFloat = 0

    init(pageCount: Int, @ViewBuilder content: () -> Content) {
        self.pageCount = pageCount
        self.content = content()
        self.currentIndex = 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HStack(spacing: 0) {
                    self.content.frame(width: geometry.size.width)
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .offset(x: -CGFloat(self.currentIndex) * geometry.size.width)
                .offset(x: self.translation)
                .animation(.interactiveSpring())
                .gesture(
                    DragGesture().updating(self.$translation) { value, state, _ in
                        state = value.translation.width
                    }.onEnded { value in
                        let offset = value.translation.width / geometry.size.width
                        let newIndex = (CGFloat(self.currentIndex) - offset).rounded()
                        self.currentIndex = min(max(Int(newIndex), 0), self.pageCount - 1)
                    }
                )
                
                if self.pageCount > 1 {
                VStack {
                    Spacer()
                    
                    ZStack{
                        //this is a hack and i should be quartered and drawn for this
                        //this essentially puts a black bg behind the pager control
                        //which is a uiviewrepresentable, but we can't really add a good
                        //background. this will have to work for now.
                        //forgive my sins,
                        //James Hall 07-17-2020.
                        Text("")
                            .padding(.horizontal, CGFloat(self.pageCount * 8))
                            .background(Color.black.opacity(0.45))
                            .cornerRadius(8)
                        HStack {
                            ForEach(0..<self.pageCount, id: \.self) { index in
                                Circle()
                                    .fill(index == self.currentIndex ? Color.white : Color.gray)
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                    
                    
                    
                }
                    .padding(.horizontal, 24)
                .offset(y: -16)
                }
            }
        }
    }
}
