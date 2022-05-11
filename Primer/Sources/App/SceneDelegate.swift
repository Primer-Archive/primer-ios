//
//  SceneDelegate.swift
//  PrimerTwo
//
//  Created by Timothy Donnelly on 10/19/19.
//  Copyright © 2019 Timothy Donnelly. All rights reserved.
//

import UIKit
import SwiftUI
import PrimerEngine
import Combine
import Sentry

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    lazy var navigation = NavigationCoordinator()

    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
                
            window.rootViewController = UIHostingController(rootView: MainView().environment(\.navigationCoordinator, navigation))
            self.window = window
            window.makeKeyAndVisible()
            window.tintColor = UIColor(red:0.35, green:0.43, blue:0.76, alpha: 1.0)
            
            do {
                Client.shared = try Client(dsn: ENV.sentryDSN)
                try Client.shared?.startCrashHandler()
            } catch let error {
                print("\(error)")
            }
            
            if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
                let seconds = 1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    // Put your code which should be executed with a delay here
                    self.handleActivity(userActivity: userActivity)
                }
                
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
           // Get URL components from the incoming user activity
          handleActivity(userActivity: userActivity)
   }
    
    private func handleActivity(userActivity: NSUserActivity){
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
                      let incomingURL = userActivity.webpageURL else {
                       return
                  }

        navigation.deepLinkURL.send(incomingURL)

    }


}

