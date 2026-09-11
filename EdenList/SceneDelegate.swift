//
//  SceneDelegate.swift
//  EdenList
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else { return }

		// Since Main is declared as the scene's storyboard in the Info.plist scene
		// manifest, UIKit has already built window + rootViewController by the time
		// this runs; `self.window` is populated automatically. Do NOT construct a
		// new UIWindow here.
		self.window = windowScene.windows.first

		// Moved from AppDelegate.application(_:didFinishLaunchingWithOptions:)
		window?.backgroundColor = UIColor.customBackgroundColor

		// Cold launch via "Open in EdenList" (Files/Mail/AirDrop) lands here.
		if let urlContext = connectionOptions.urlContexts.first {
			handleIncomingURL(urlContext.url)
		}
	}

	// Moved from AppDelegate.application(_:open:options:) — fires when the app
	// is already running and the user opens/imports another .edenlist file.
	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		guard let urlContext = URLContexts.first else { return }
		_ = handleIncomingURL(urlContext.url)
	}

	@discardableResult
	private func handleIncomingURL(_ url: URL) -> Bool {

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

	func sceneDidDisconnect(_ scene: UIScene) {
		// Called as the scene is being released by the system.
		// This occurs shortly after the scene enters the background, or when its session is discarded.
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
}
