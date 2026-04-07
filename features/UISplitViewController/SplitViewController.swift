import UIKit

class CustomSplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.preferredDisplayMode = .oneBesideSecondary
        self.preferredPrimaryColumnWidth = 350
    }

    // Handle collapse behavior
    func splitViewController(_ svc: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        // Return true to indicate that we have handled the collapse
        return true
    }

    // Handle expand behavior
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        // Perform actions as needed when the display mode changes
    }
}