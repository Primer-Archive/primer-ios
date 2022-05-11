//
//  FullScreenSafariView.swift
//  Primer
//
//  Created by Sarah Hurtgen on 9/23/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import SafariServices


// MARK: - FullScreen View

struct FullScreenSafariView: View {
    @Environment(\.presentationMode) var presentationMode
    var url: URL
    
    var body: some View {
        SafariViewRepresentable(url: url)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Rep

struct SafariViewRepresentable: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> some UIViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        //
    }
}

// MARK: - Preview

struct FullScreenSafariView_Previews: PreviewProvider {
    static var previews: some View {
        FullScreenSafariView(url: URL(string: "https://www.primer.com")!)
    }
}
