import SwiftUI


struct PageView<Page: View>: View {
    
    var viewControllers: [UIHostingController<Page>]
    
    @State var currentPage = 0
    

    init(_ views: [Page]) {
        self.viewControllers = views.map { UIHostingController(rootView: $0) }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
                PageViewController(controllers: viewControllers, currentPage: $currentPage)
                ZStack{
                    //this is a hack and i should be quartered and drawn for this
                    //this essentially puts a black bg behind the pager control
                    //which is a uiviewrepresentable, but we can't really add a good
                    //background. this will have to work for now.
                    //forgive my sins,
                    //James Hall 07-17-2020.
                    Text("")
                        .padding(.horizontal, CGFloat(self.viewControllers.count * 10))
                        .background(Color.black.opacity(0.45))
                        .cornerRadius(6)
                    PageControl(numberOfPages: viewControllers.count, currentPage: $currentPage)
                }
                .padding(.horizontal, 36)
        }
    }
}

//struct PageView_Previews: PreviewProvider {
//    static var previews: some View {
//        ZStack{
//            ScrollView{
//                ZStack{
//                    PageView([1,2].map { Text("hey: \($0)").background(Color.red)
//                        .frame(maxWidth:.infinity,minHeight: 400)
//                    })
//                }
//
//            }
//        }
//
//
//            .aspectRatio(3 / 2, contentMode: .fit)
//    }
//}
