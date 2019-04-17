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

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.		
		NotificationCenter.default.post(name: Notification.Name(rawValue: "appWillTerminateNotification"), object: nil)
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		
		// Import a new list
		// https://www.raywenderlich.com/133825/uiactivityviewcontroller-tutorial
		// https://www.infragistics.com/community/blogs/b/stevez/posts/ios-tips-and-tricks-associate-a-file-type-with-your-app-part-3
		
		// Ensure that the file is an EdenList document
		guard url.pathExtension == "edenlist" else {
			return false
		}
		
		let listName = url.deletingPathExtension().lastPathComponent
		
		// Verify if another file already exists with the same name as listName
		if ListManager.sharedManager.listExists(listName: listName) == false {
			// This is a new list
			ListManager.sharedManager.addNewList(url: url)
			
			return navigateToNewList()
			
		} else {
			// Rename the list, then add it
			ListManager.sharedManager.addAndRenameNewList(url: url)
			
			return navigateToNewList()
		}
	}
	
	/// Notify the HomeViewController to refresh its list, then go to the new list
	///
	/// - Returns: If this can successfully navigate to the imported list, return true.  On a failure, return false.
	private func navigateToNewList() -> Bool {
		
		// Grab the root view controller
		guard let navigationController = window?.rootViewController as? UINavigationController,
			let homeViewController = navigationController.viewControllers.first as? HomeViewController else {
				// If the HomeViewController isn't found, kick out
				return false
		}
		
		// Pop back to the root view controller then tell the HomeViewController to navigate to the new list
		navigationController.popViewController(animated: false)
		homeViewController.refreshList()
		
		return true
	}
}
