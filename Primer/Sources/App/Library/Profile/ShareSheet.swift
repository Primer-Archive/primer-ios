//
//  ShareSheet.swift
//  PrimerTwo
//
//  Created by Zack Shapiro on 10/30/19.
//  Copyright © 2019 Timothy Donnelly. All rights reserved.
//

import SwiftUI


struct ShareSheet: UIViewControllerRepresentable {

    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void

    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil
    let callback: Callback? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities)
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // nothing to do here
    }

}


struct ShareSheet_Previews: PreviewProvider {
    static var previews: some View {
        ShareSheet(activityItems: [])
    }
}
