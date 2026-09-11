//
//  AppDelegate.swift
//  EdenList
//
//  Created by Chad Armstrong on 2/14/17.
//  Copyright © 2017 Edenwaith. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		
		// Override point for customization after application launch.
		// Window setup now happens per-scene in SceneDelegate.
		
		return true
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.		
		NotificationCenter.default.post(name: Notification.Name(rawValue: "appWillTerminateNotification"), object: nil)
	}
}
