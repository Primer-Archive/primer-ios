//
//  InspirationTilesView.swift
//  PrimerTwo
//
//  Created by Adam Debreczeni on 11/25/19.
//  Copyright © 2019 Timothy Donnelly. All rights reserved.
//
//
//import SwiftUI
//import Grid
//
//struct InspirationTilesView: View {
//    
//    @State var style = StaggeredGridStyle(tracks: .min(140), spacing: 6, padding: .init(top: 6, leading: 6, bottom: 6, trailing: 6))
//    
//    var data = [
//        ProductCollection.chasingPaperSample.products[0],
//        ProductCollection.chasingPaperSample.products[1],
//        ProductCollection.chasingPaperSample.products[2],
//        ProductCollection.chasingPaperSample.products[3],
//        ProductCollection.chasingPaperSample.products[4],
//        ProductCollection.chasingPaperSample.products[5],
//        ProductCollection.karenSample.products[0],
//        ProductCollection.karenSample.products[1],
//        ProductCollection.karenSample.products[2],
//        ProductCollection.tileSample.products[1],
//        ProductCollection.tileSample.products[2],
//        ProductCollection.tileSample.products[3]
//    ]
//    
//    var body: some View {
//        
//            Grid(0...data.count-1, id: \.self) { index in
//                
//                Image(self.data[index].productImages[0])
//                    .resizable()
//                    .scaledToFit()
//                
//            }
//        
//        .gridStyle(
//            self.style
//        )
//
//    }
//}
//
//struct InspirationTilesView_Previews: PreviewProvider {
//    static var previews: some View {
//        InspirationTilesView()
//    }
//}
