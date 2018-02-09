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


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
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

	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		
		// https://www.infragistics.com/community/blogs/b/stevez/posts/ios-tips-and-tricks-associate-a-file-type-with-your-app-part-3
		/*
		NSFileManager *filemgr = [NSFileManager defaultManager];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		NSString* inboxPath = [documentsDirectory stringByAppendingPathComponent:@"Inbox"];
		NSArray *dirFiles = [filemgr contentsOfDirectoryAtPath:inboxPath error:nil];
		*/
		
		// TODO: Steps when importing a file
		// 1. Verify if another file already exists with that file name
		// 2. If not, add the new file (copy to proper directory and add to the list
		// 3. If another file already exists, give the user the option to either merge the new list, rename the new list, or cancel
		
		// Ensure that the file is an EdenList document
		guard url.pathExtension == "edenlist" else {
			return false
		}
		
		let listName = url.lastPathComponent
		
		if ListManager.sharedManager.listExists(listName: listName) == false {
			ListManager.sharedManager.addNewList(url: url)
		} else {
			print("The list \(listName) already exists")
		}
		
		return true // return false if the application failed to open the file
	}
}

