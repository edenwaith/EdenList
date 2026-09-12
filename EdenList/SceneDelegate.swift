//
//  SceneDelegate.swift
//  EdenList
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else { return }

		let window = UIWindow(windowScene: windowScene)

		// Root view controller is built programmatically (a UISplitViewController)
		// rather than loaded from the storyboard's initial view controller, so the
		// scene manifest's UISceneStoryboardFile key was removed from Info.plist.
		// HomeViewController is still loaded from Main.storyboard by identifier,
		// consistent with how every other screen in this app is instantiated.
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		guard let homeViewController = storyboard.instantiateViewController(withIdentifier: "homeViewControllerID") as? HomeViewController else {
			fatalError("Could not instantiate HomeViewController from Main.storyboard")
		}

		let primaryNavigationController = UINavigationController(rootViewController: homeViewController)

		// HomeViewController's large title used to come from the storyboard's
		// navigation controller scene (Main.storyboard, "Prefers Large Titles"
		// checked, largeTitles="YES" on its navigation bar). Now that the app
		// builds its root navigation controller in code instead of loading that
		// storyboard scene, that setting has to be set explicitly here.
		// ListItemsViewController and EditItemViewController both already opt out
		// per-screen via navigationItem.largeTitleDisplayMode = .never, so this
		// only affects HomeViewController (and, on iPhone, the shared primary
		// stack it collapses into).
		primaryNavigationController.navigationBar.prefersLargeTitles = true

		// Secondary (detail) column starts out showing a placeholder until a list
		// is selected. On iPad (expanded) this is what's visible until the user
		// taps a list. On iPhone (collapsed), a split view controller that STARTS
		// out collapsed (rather than collapsing live from an expanded state) has
		// no "collapse transition" to intercept, so splitViewController(_:collapseSecondary:onto:)
		// below does NOT run for this initial case — it only matters for a later,
		// genuine expanded-to-collapsed transition (e.g. resizing on iPad). The
		// fix for the launch case is the explicit splitViewController.show(.primary)
		// call further down, right after the window is made visible.
		let noListSelectedViewController = NoListSelectedViewController()
		let secondaryNavigationController = UINavigationController(rootViewController: noListSelectedViewController)

		let splitViewController = UISplitViewController(style: .doubleColumn)
		splitViewController.viewControllers = [primaryNavigationController, secondaryNavigationController]
		splitViewController.preferredDisplayMode = .automatic
		splitViewController.preferredSplitBehavior = .tile
		splitViewController.delegate = self

		self.window = window
		window.rootViewController = splitViewController

		// Moved from AppDelegate.application(_:didFinishLaunchingWithOptions:)
		window.backgroundColor = UIColor.customBackgroundColor
		window.makeKeyAndVisible()

		// Explicitly show the primary column (Home) once the window is visible.
		// Without this, a UISplitViewController that starts out collapsed (iPhone)
		// defaults to showing the secondary column's content — the "no list
		// selected" placeholder — rather than the primary, since nothing has been
		// "shown" yet and there's no actual collapse transition happening (it
		// starts collapsed) to trigger splitViewController(_:collapseSecondary:onto:)
		// below. This makes Home the visible screen at launch as expected; Home's
		// own viewDidAppear -> checkForRecentList() then pushes the last-viewed
		// list on top of it, same as it always has.
		splitViewController.show(.primary)

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

		// Grab the primary column's navigation controller and its root HomeViewController.
		// (window.rootViewController is now a UISplitViewController, not a bare
		// UINavigationController, since the app adopted a multi-column layout.)
		guard let splitViewController = window?.rootViewController as? UISplitViewController,
			let navigationController = splitViewController.viewController(for: .primary) as? UINavigationController,
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

// MARK: - UISplitViewControllerDelegate

extension SceneDelegate: UISplitViewControllerDelegate {

	// Called when the split view controller collapses from two columns down to
	// one (e.g. on iPhone at launch, or when narrowing past the compact-width
	// boundary on iPad). Returning true tells UIKit "I've handled this myself,
	// don't perform your default behavior" — used here only to discard the
	// empty "no list selected" placeholder so it doesn't get pushed on top of
	// HomeViewController. Returning false for anything else lets UIKit fall
	// back to its normal behavior of pushing real secondary content (an actual
	// list, possibly with an item being edited) onto the primary stack.
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		if let secondaryNavigationController = secondaryViewController as? UINavigationController,
			secondaryNavigationController.viewControllers.first is NoListSelectedViewController {
			return true
		}

		return false
	}
}
