//
//  EditItemViewController.swift
//  EdenList
//
//  Created by Chad Armstrong on 2/22/17.
//  Copyright © 2017 Edenwaith. All rights reserved.
//

import UIKit

// MARK: - EditItemRow enumerated type

enum EditItemRow: Int {
	case item  = 0
	case notes = 1
}

// MARK: - EditItemControllerDelegate Protocol

protocol EditItemControllerDelegate: AnyObject  {
	func addNewItem(item: ListItem)
	func editItem(item: ListItem, at index: Int)
}

// MARK: - EditItemViewController

class EditItemViewController: UITableViewController {

	var isNewItem: Bool = true
	var listItem: ListItem?
	var tempItem: ListItem?
	var rowNumber: Int?
	var keyboardToolbar: UIToolbar?
	var textFieldBeingEdited: UITextField?
	weak var delegate: EditItemControllerDelegate?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		setupUI()
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if isNewItem == true {
			self.selectItemTextField()
		}
	}
	
	// MARK: - Custom Methods
	
	func setupUI() {
		
		// Copy over the item data, if it exists
		if let listItem = self.listItem {
			self.tempItem = listItem.copy()
		} else {
			self.tempItem = ListItem()
		}
		
		// Configure navigation bar items
		let cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
		let saveButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
		
		// Good reference for the large titles: https://chariotsolutions.com/blog/post/large-titles-ios-11/
		self.navigationItem.largeTitleDisplayMode = .never
		self.navigationItem.leftBarButtonItem = cancelButtonItem
		self.navigationItem.rightBarButtonItem = saveButtonItem
		self.navigationController?.navigationBar.isTranslucent = false
		
		// Set up view controller title
		if isNewItem == true {
			self.title = "New Item".localize()
		} else {
			self.title = listItem?.itemTitle
		}
		
		self.setupKeyboardToolbar()
	}

	/// Setup the input view accessory for the keyboard to easily cycle through the fields
	func setupKeyboardToolbar() {

		let dismissButton = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(dismissKeyboard))
		let flexibleButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		let spaceButton = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
		let previousButton = UIBarButtonItem(image: UIImage(named: "arrow_left"), style: .plain, target: self, action: #selector(selectItemTextField))
		let nextButton = UIBarButtonItem(image: UIImage(named: "arrow_right"), style: .plain, target: self, action: #selector(selectNotesTextField))
		
		keyboardToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 44))
		
		spaceButton.width = 20.0
		
		dismissButton.accessibilityLabel = "Dismiss keyboard".localize()
		previousButton.accessibilityLabel = "Previous".localize()
		nextButton.accessibilityLabel = "Next".localize()
		
		keyboardToolbar?.items = [previousButton, spaceButton, nextButton, flexibleButton, dismissButton]
	}
	
	/// Make the Item text field active
	@objc func selectItemTextField() {
		let indexPath = IndexPath(row: 0, section: 0)
		self.selectTextField(at: indexPath)
	}
	
	/// Make the Notes text field active
	@objc func selectNotesTextField() {
		let indexPath = IndexPath(row: 1, section: 0)
		self.selectTextField(at: indexPath)
	}
	
	/// Utility method to select the text field at a given index path
	func selectTextField(at indexPath: IndexPath) {
		if let activeCell = self.tableView.cellForRow(at: indexPath) as? EditItemTableViewCell {
			activeCell.textField.becomeFirstResponder()
		}
	}
	
	/// Enable the Next button and disable the Previous button
	func itemFieldBecameActive() {
		if let accessoryButtons = self.keyboardToolbar?.items {
			let previousButton:UIBarButtonItem = accessoryButtons[0]
			let nextButton:UIBarButtonItem = accessoryButtons[2]
			
			previousButton.isEnabled = false
			nextButton.isEnabled = true
		}
	}
	
	/// Enable the Previous button and disable the Next button
	func notesFieldBecameActive() {
		if let accessoryButtons = self.keyboardToolbar?.items {
			let previousButton:UIBarButtonItem = accessoryButtons[0]
			let nextButton:UIBarButtonItem = accessoryButtons[2]
			
			previousButton.isEnabled = true
			nextButton.isEnabled = false
		}
	}
	
	// MARK: - IBActions
	
	@IBAction func dismissKeyboard() {
		self.view.endEditing(true)
	}
	
	@IBAction func cancel() {
		// popViewController returns a UIViewController, which throws a warning if not assigned
		_ = self.navigationController?.popViewController(animated: true)
	}
	
	@IBAction func save() {
		
		if let textField = self.textFieldBeingEdited {
			if textField.tag == EditItemRow.item.rawValue {
				tempItem?.itemTitle = textField.text!
			} else if textField.tag == EditItemRow.notes.rawValue {
				tempItem?.itemNotes = textField.text!
			}
		}

		if isNewItem == true {
			self.delegate?.addNewItem(item: tempItem!)
		} else {
			self.delegate?.editItem(item: tempItem!, at: rowNumber!)
		}
		
		_ = self.navigationController?.popViewController(animated: true)
	}
	
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemReuseID", for: indexPath) as! EditItemTableViewCell

		cell.selectionStyle = .none
		cell.textField.delegate = self
		cell.textField.tag = indexPath.row
		cell.textField.inputAccessoryView = self.keyboardToolbar
		
        // Configure the cell...
		if indexPath.row == EditItemRow.item.rawValue {
			cell.itemLabel.text = "item".localize()
			cell.textField.text = self.tempItem?.itemTitle
			cell.textField.returnKeyType = .done
		} else { // Notes
			cell.itemLabel.text = "notes".localize()
			cell.textField.text = self.tempItem?.itemNotes
			cell.textField.returnKeyType = .done
		}

        return cell
    }
	
	// MARK: - Table view delegate
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.selectTextField(at: indexPath)
	}
}

// MARK: - UITextFieldDelegate

extension EditItemViewController: UITextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		self.textFieldBeingEdited = textField
		
		if textField.tag == EditItemRow.item.rawValue {
			self.itemFieldBecameActive()
		} else if textField.tag == EditItemRow.notes.rawValue {
			self.notesFieldBecameActive()
		}
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
		if textField.tag == EditItemRow.item.rawValue {
			tempItem?.itemTitle = textField.text!
		} else if textField.tag == EditItemRow.notes.rawValue {
			tempItem?.itemNotes = textField.text!
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		
		if textField.tag == EditItemRow.item.rawValue { // Next button
			textField.resignFirstResponder()
			self.save()
		} else { // Done button
			textField.resignFirstResponder()
			self.save()
		}
		
		return false
	}
}
