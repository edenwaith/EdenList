//
//  NoListSelectedViewController.swift
//  EdenList
//
//  Created for the UISplitViewController migration.
//  Shown in the detail column when no list has been selected yet
//  (e.g. on iPad, before the user taps a list in the sidebar).
//

import UIKit

class NoListSelectedViewController: UIViewController {

	private let messageLabel: UILabel = {
		let label = UILabel()
		label.text = "Select a list".localize()
		label.textColor = UIColor.customGrey
		label.font = UIFont.preferredFont(forTextStyle: .title3)
		label.textAlignment = .center
		label.numberOfLines = 0
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = UIColor.customBackgroundColor
		title = "EdenList"

		view.addSubview(messageLabel)

		NSLayoutConstraint.activate([
			messageLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
			messageLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
			messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
			messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32)
		])
	}
}
