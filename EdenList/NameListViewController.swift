//
//  NameListViewController.swift
//  EdenList
//
//  Created by Chad Armstrong on 2/19/17.
//  Copyright © 2017 Edenwaith. All rights reserved.
//

import UIKit

protocol NameListViewControllerDelegate: class {
	func nameListUpdated(with name: String, with row: Int)
	func nameListViewCanceled() // Consider if this is necessary or not
}

class NameListViewController: UITableViewController {

	var isNewList: Bool = true
	var rowNumber: Int = -1
	var listName: String = ""
	weak var delegate: NameListViewControllerDelegate?
	
	@IBOutlet weak var textField: UITextField!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		setupUI()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Set up the textfield
		self.textField.becomeFirstResponder()
	}

	func setupUI() {
		// View title
		if self.isNewList == true {
			self.navigationItem.title = "Add New List".localize()
		} else {
			self.navigationItem.title = "Edit List Name".localize()
		}
		
		// Cancel button
		let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction(sender:)))
		self.navigationItem.leftBarButtonItem = cancelButton
		self.navigationItem.leftBarButtonItem?.isEnabled = true
		
		// Save button
		let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveAction(sender:)))
		self.navigationItem.rightBarButtonItem = saveButton
		self.navigationItem.rightBarButtonItem?.isEnabled = false
		
		// Table view + cell
		self.tableView.rowHeight = UITableView.automaticDimension
		self.tableView.estimatedRowHeight = 44
		
		// Textfield
		if listName.isEmpty == false {
			self.textField.text = listName
			// self.navigationItem.rightBarButtonItem?.isEnabled = true // Maybe not, since we may not want this to be enabled until the title has been changed
		}
	}
	
	// MARK: - IBActions
	
	@IBAction func cancelAction(sender: UIBarButtonItem) {
		self.view.endEditing(true)
		
		self.dismiss(animated: true, completion: {
			self.delegate?.nameListViewCanceled()
		})
	}
	
	@IBAction func saveAction(sender: UIBarButtonItem?) {
		
		if let text = textField.text {
			self.listName = text
		}
		
		self.view.endEditing(true)
		
		self.dismiss(animated: true, completion: {
			self.delegate?.nameListUpdated(with: self.listName, with: self.rowNumber)
		})
	}
	
}

// MARK: - UITextFieldDelegate Methods

extension NameListViewController: UITextFieldDelegate {
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		
		let textFieldCount = textField.text?.count ?? 0
		
		if (textFieldCount + string.count - range.length) > 0 {
			self.navigationItem.rightBarButtonItem?.isEnabled = true
		} else {
			self.navigationItem.rightBarButtonItem?.isEnabled = false
		}
		
		return true
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		self.navigationItem.rightBarButtonItem?.isEnabled = false
		return true
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {

		if let text = textField.text {
			self.listName = text
		}
		
		if self.listName.isEmpty == false {
			self.saveAction(sender: nil)
		}
		
		return true
	}
}
