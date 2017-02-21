//
//  HomeViewController.swift
//  EdenList
//
//  Created by Chad Armstrong on 2/14/17.
//  Copyright © 2017 Edenwaith. All rights reserved.
//

import UIKit

class HomeViewController: UITableViewController {

	var records = [String]()
	let listManager = ListManager.sharedManager
	
    override func viewDidLoad() {
        super.viewDidLoad()

		loadLists()
		setupUI()
    }

	func loadLists() {
		// Load lists
		if let listsArray = listManager.lists() as? [String], listsArray.count > 0 { // UserDefaults.standard.array(forKey: "Lists") as? [String] {
			self.records = listsArray
		} else {
			self.records = ["Foo", "Bar"] // TODO: Temp code
			// TODO: Display empty view
		}
	}
	
	func saveLists() {
		// listManager.saveLists(self.records)
	}
	
	func setupUI() {
		// Setup UI
		let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewList))
		self.navigationItem.leftBarButtonItem = self.editButtonItem
		self.navigationItem.rightBarButtonItem = addButton
		self.navigationItem.title = NSLocalizedString("EdenList", comment:"")
		
		// Don't display empty "cells"
		self.tableView.tableFooterView = UIView()
	}
	
	
	@IBAction func addNewList() {
		
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		
		if let nameListController = storyboard.instantiateViewController(withIdentifier: "nameListViewControllerID") as? NameListViewController {
			nameListController.isNewList = true
			nameListController.delegate = self
			
			// Need to add a navigation controller to wrap around this VC, since the view is being presented modally
			let navigationVC = UINavigationController(rootViewController: nameListController)
			
			self.navigationController?.present(navigationVC, animated: true, completion: nil)
		}
	}
	
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.records.count
    }

	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...
		cell.textLabel?.text = self.records[indexPath.row]
		cell.accessibilityHint = NSLocalizedString("Tappable", comment: "Tappable")

        return cell
    }

	// MARK: - Table view delegate
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		if self.tableView.isEditing == true {
			
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			
			if let nameListController = storyboard.instantiateViewController(withIdentifier: "nameListViewControllerID") as? NameListViewController {
				let itemName = self.records[indexPath.row]
				nameListController.isNewList = false
				nameListController.delegate = self
				nameListController.listName = itemName
				nameListController.rowNumber = indexPath.row
			
				// Need to add a navigation controller to wrap around this VC, since the view is being presented modally
				let navigationVC = UINavigationController(rootViewController: nameListController)
				// TODO: Add any additional code which might be needed for larger devices (iPad, iPhone Plus, etc.)
				self.navigationController?.present(navigationVC, animated: true, completion: nil)
			}
		} else {
			self.displayListAtIndex(indexPath: indexPath)
		}
	}
	
	// MARK: - Edit Rows
	
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
			self.records.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		let fromRow = fromIndexPath.row
		let toRow = to.row
		
		let record = self.records[fromRow]
		self.records.remove(at: fromRow)
		self.records.insert(record, at: toRow)
		
		self.saveLists()
    }
	
	// MARK: - Utility Methods
	
	func displayListAtIndex(indexPath: IndexPath) {
		
	}
	
	func checkIfNameExists(name: String) -> Bool {
		return self.records.contains(name)
	}

}

// MARK: - NameListViewControllerDelegate Methods

extension HomeViewController: NameListViewControllerDelegate {
	
	func nameListUpdated(with name: String, with row: Int) {

		let nameAlreadyExists = self.checkIfNameExists(name: name)
		let trimmedString = name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) // trim all whitespace
		
		if nameAlreadyExists == true {
			
			let msg = NSLocalizedString("Another list is already using the name \"\(name)\".  Please try another name.", comment: "")
			let alert = UIAlertController(title: NSLocalizedString("Warning", comment: "Warning"), message: msg, preferredStyle: .alert)
			let defaultAction = UIAlertAction(title: NSLocalizedString("OK", comment:"OK"), style: .default, handler: nil)
			alert.addAction(defaultAction)
			
			present(alert, animated: true, completion: nil)
			
		} else if trimmedString.characters.count == 0 { // Empty name
			
			let msg = NSLocalizedString("The list name cannot be blank.  Please enter in a name for your list", comment: "")
			let alert = UIAlertController(title: NSLocalizedString("Warning", comment: "Warning"), message: msg, preferredStyle: .alert)
			let defaultAction = UIAlertAction(title: NSLocalizedString("OK", comment:"OK"), style: .default, handler: nil)
			alert.addAction(defaultAction)
			
			present(alert, animated: true, completion: nil)
			
		} else if row < 0 { // New list
			
			if nameAlreadyExists == false {
				self.records.append(name)
				self.navigationItem.leftBarButtonItem?.isEnabled = true
				self.tableView.reloadData()
				
				// Scroll to the bottom of the list when a new item has been added.
				let scrollIndexPath = IndexPath(row: self.records.count - 1, section: 0) // [NSIndexPath indexPathForRow:([records count]-1) inSection:0];
				self.tableView.scrollToRow(at: scrollIndexPath, at: .top, animated: true)
				
				self.saveLists()
				
				// TODO: Consider whether or not to keep this implementation
				// self.displayListAtIndex(indexPath: scrollIndexPath)
			}
			
		} else if row >= 0 { // Renaming a list
			
			let oldFileName = self.records[row]
			self.records[row] = name
			
			// TODO: Move a majority of this functionality to the ListManager
			
			// TODO: Look into using the FileManager, instead
			let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
			
			let documentsDirectory: URL = URL(fileURLWithPath:paths.first!)
			
			let oldFilePath = documentsDirectory.appendingPathComponent("\(oldFileName).edenlist").path
			let newFilePath = documentsDirectory.appendingPathComponent("\(name).edenlist").path

			if FileManager.default.fileExists(atPath: oldFilePath) {
				do {
					try FileManager.default.moveItem(atPath: oldFilePath, toPath: newFilePath)
				} catch {
					print("Could not move paths")
				}
			}
			
			
			self.tableView.reloadData()
			self.saveLists()
		}
	}
	
	func nameListViewCanceled() {
		
	}
}
