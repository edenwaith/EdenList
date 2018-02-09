//
//  ListItemsViewController.swift
//  EdenList
//
//  Created by Chad Armstrong on 2/22/17.
//  Copyright © 2017 Edenwaith. All rights reserved.
//

import UIKit

enum VisibilityState: Int {
	case all 		= 0
	case unchecked 	= 1
	
	init?(rawValue: Int) {
		switch rawValue {
		case 0:  self = .all
		case 1:  self = .unchecked
		default: self = .all
		}
	}
}

enum ListKey: String {
	case toDo 		= "ToDo"
	case notes 		= "Notes"
	case checkBox 	= "CheckBox"
	case index 		= "Index"
}

class ListItemsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var organizationControl: UISegmentedControl!
	
	var records = [ListItem]()
	var visibleRecords = [ListItem]()
	
	var filePath: String = ""
	var visibilityState: VisibilityState = .all
	
	// MARK: - View Life Cycle
	
    override func viewDidLoad() {
        super.viewDidLoad()

		openFile()
        setupUI()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.reloadData()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.saveFile()
	}
	
	// MARK: -
	
	func setupUI() {
		// Add navigation bar items
		let actionButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonTapped))
		actionButtonItem.style = UIBarButtonItemStyle.plain
		
		self.navigationItem.rightBarButtonItems = [self.editButtonItem, actionButtonItem]
		
		self.tableView.tableFooterView = UIView()
	}
	
	// MARK: - IBActions
	
	func shareButtonTapped(_ sender: UIBarButtonItem) {
		
		let fileTitle = self.title // TODO: Change this to the actual file to share
		let fileURL = NSURL(fileURLWithPath: self.filePath)
		
		let excludedTypes:[UIActivityType] = [.postToFacebook, .postToTwitter, .postToVimeo, .postToWeibo, .postToFlickr, .addToReadingList]
		let shareVC = UIActivityViewController(activityItems: [fileTitle, fileURL], applicationActivities: nil)
		shareVC.excludedActivityTypes = excludedTypes
		
		// shareVC.popoverPresentationController?.sourceView = sender
		
		if let popoverPresentationController = shareVC.popoverPresentationController {
			popoverPresentationController.barButtonItem = sender // (sender as! UIBarButtonItem)
		}
		
		self.present(shareVC, animated: true, completion: nil)
		
	}
	
	@IBAction func addItem(_ sender: AnyObject) {
		
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		
		if let editItemController = storyboard.instantiateViewController(withIdentifier: "editItemViewControllerID") as? EditItemViewController {
			editItemController.title = "New Item".localize()
			editItemController.delegate = self
			self.navigationController?.pushViewController(editItemController, animated: true)
		}
	}
	
	@IBAction func deleteItems(_ sender: AnyObject) {

		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		
		let deleteAllOption = UIAlertAction(title: "Delete All".localize(), style: .destructive) { (alert: UIAlertAction) -> Void in
			self.deleteAllItems()
		}
		
		let deleteCheckedOption = UIAlertAction(title: "Delete Checked".localize(), style: .destructive) { (alert: UIAlertAction) -> Void in
			self.deleteCheckedItems()
		}
		
		let deleteUncheckedOption = UIAlertAction(title: "Delete Unchecked".localize(), style: .destructive) { (alert: UIAlertAction) -> Void in
			self.deleteUncheckedItems()
			
		}
		
		alert.addAction(deleteAllOption)
		alert.addAction(deleteCheckedOption)
		alert.addAction(deleteUncheckedOption)
		alert.addAction(UIAlertAction(title: "Cancel".localize(), style: UIAlertActionStyle.cancel, handler: nil))
		
		if let popoverPresentationController = alert.popoverPresentationController {
			// Pop over for larger screens (e.g. iPad)
			popoverPresentationController.barButtonItem = (sender as! UIBarButtonItem)
		}
		
		// Display the action sheet
		present(alert, animated: true) {}
	}

	@IBAction func organizationChanged(_ sender: UISegmentedControl) {
		self.visibilityState = VisibilityState(rawValue: sender.selectedSegmentIndex)!
		self.updateVisibleRecords()
	}
	
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.visibleRecords.count
    }
	
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "listItemReuseID", for: indexPath)

		let item:ListItem = self.visibleRecords[indexPath.row]
		
        // Configure the cell...
		cell.textLabel?.text = item.itemTitle
		cell.detailTextLabel?.text = item.itemNotes

		cell.imageView?.image = item.itemChecked ? #imageLiteral(resourceName: "checked") : #imageLiteral(resourceName: "unchecked")
		cell.accessoryType =  .detailDisclosureButton
		cell.accessibilityHint = NSLocalizedString("Checked", comment: "Checked")
		
        return cell
    }
	
	// MARK: - Table view delegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		if self.visibilityState == .all {
			
			let row = indexPath.row
			let item = self.records[row]
			item.itemChecked = !item.itemChecked
			
			self.records[row] = item // update the records with the modified ListItem
			
			self.saveFile()
			self.updateVisibleRecords()
			
		} else { // Unchecked
			
			let row = indexPath.row
			let item = self.visibleRecords[row]
			let tempIndex = item.itemIndex
			item.itemChecked = !item.itemChecked
			
			self.records[tempIndex] = item
			self.tableView.reloadData() // Immediately update the table to briefly show the checked item
			
			self.saveFile()
			
			// After tapping, wait briefly to allow the user to select multiple items before refreshing the visible records
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateVisibleRecords), object: nil) // cancel any previous requests
			self.perform(#selector(updateVisibleRecords), with: nil, afterDelay: 0.7)
		}
	}
	
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
	
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		
        if editingStyle == .delete {
            // Delete the row from the data source
			let row = indexPath.row
			
			if self.visibilityState == .all {
				
				self.records.remove(at: row)
				self.updateVisibleRecords()
				
			} else if self.visibilityState == .unchecked {
				
				let selectedObject = self.visibleRecords[row]
				let originalIndex = selectedObject.itemIndex
				
				if originalIndex >= 0 {
					self.records.remove(at: originalIndex)
				}
				
				self.updateVisibleRecords()
			}
			
			if self.visibleRecords.count <= 0 {
				self.navigationController?.setEditing(false, animated: true)
				self.editButtonItem.isEnabled = false
			}
			
			self.saveFile()
			
        } else if editingStyle == .insert {
			// Currently unused
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

	func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
		
		var row: Int = indexPath.row
		let listItem = self.visibleRecords[row]
		
		if self.visibilityState == .unchecked {
			// Send the index of the full records, not just the visible records
			let item = self.visibleRecords[row]
			let index = item.itemIndex
			
			row = index
		}
		
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		
		if let editItemController = storyboard.instantiateViewController(withIdentifier: "editItemViewControllerID") as? EditItemViewController {
			editItemController.title = listItem.itemTitle
			editItemController.listItem = listItem
			editItemController.rowNumber = row
			editItemController.isNewItem = false
			editItemController.delegate = self
			self.navigationController?.pushViewController(editItemController, animated: true)
		}
	}
	
	/// Sets whether a view control displays an editable view.
	/// This is called when the Edit/Done button is tapped.
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		if self.records.count > 0 {
			self.editButtonItem.isEnabled = true
			self.tableView.setEditing(editing, animated: true)
		} else {
			self.editButtonItem.isEnabled = false
			self.tableView.setEditing(editing, animated: animated)
		}
	}
	
	
    // Override to support rearranging the table view.
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		
		let fromRow = fromIndexPath.row
		let toRow = to.row
		let originalItem = self.records[fromRow]
		
		self.records.remove(at: fromRow)
		self.records.insert(originalItem, at: toRow)
		
		// Update visibleRecords this way, instead of updateVisibleRecords method, which
		// was causing some visual issues
		// Side note: This may or may not be necessary any longer
		self.visibleRecords.remove(at: fromRow)
		self.visibleRecords.insert(originalItem, at: toRow)

		self.saveFile()
    }

    // Override to support conditional rearranging of the table view.
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
		if self.visibilityState == .all {
        	return true
		} else { // Show only unchecked items
			return false
		}
    }

	/// After a change in the table's data, update the appearance.
	/// If the table is empty, display an appropriate message.
	/// Enable/disable the Edit button
	///
	/// - Parameter forceReload: Option to reload the table's data before determining what to display
	func reloadData(forceReload: Bool = true) {
		
		if forceReload == true {
			self.tableView.reloadData()
		}
		
		if records.count == 0 {
			
			let message = "This list is empty.".localize()
			let messageLabel = UILabel(frame: CGRect(x:0, y:0, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height))
			
			messageLabel.text = message
			messageLabel.textColor = UIColor.darkGray
			messageLabel.numberOfLines = 0;
			messageLabel.textAlignment = .center;
			messageLabel.font =  UIFont.systemFont(ofSize: 15.0)
			messageLabel.sizeToFit()
			
			self.tableView.backgroundView = messageLabel
			
			self.editButtonItem.isEnabled = false // Disable the Edit button
			self.tableView.isEditing = false
			self.navigationController?.isEditing = false
			
		} else {
			self.tableView.backgroundView = nil
			self.editButtonItem.isEnabled = true
		}
	}
	
	// MARK: - Custom Methods
	
	func deleteAllItems() {
		self.records.removeAll()
		self.updateVisibleRecords()
		self.saveFile()
	}
	
	// Fun side note: The equivalent Objective-C method was 20 lines of code, compared to about half that here
	func deleteCheckedItems() {
		
		let recordsCount = self.records.count
		
		for (index, record) in self.records.reversed().enumerated() {
			if record.itemChecked == true {
				// index is returned sequentially, not in reverse order, so the proper index needs to be calculated
				let itemIndex = recordsCount - index - 1
				print("Delete \(record.itemTitle) index:: \(index) itemIndex:: \(itemIndex)")
				self.records.remove(at: itemIndex)
			}
		}
		
		self.updateVisibleRecords()
		self.saveFile()
	}
	
	func deleteUncheckedItems() {
		
		let recordsCount = self.records.count
		
		for (index, record) in self.records.reversed().enumerated() {
			if record.itemChecked == false {
				// index is returned sequentially, not in reverse order, so the proper index needs to be calculated
				let itemIndex = recordsCount - index - 1
				self.records.remove(at: itemIndex)
			}
		}
		
		self.updateVisibleRecords()
		self.saveFile()
	}
	
	func updateVisibleRecords() {
		
		self.visibleRecords.removeAll()
		
		if self.visibilityState == .unchecked { // Unchecked items
			for (index, item) in self.records.enumerated() {
				
				let tempItem:ListItem = item
				let checkedStatus = item.itemChecked
				
				// If the item has not been checked, add it to the visible records
				if checkedStatus == false {
					tempItem.itemIndex = index
					self.visibleRecords.append(tempItem)
				}
			}
			
			self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
			
		} else { // All items
			
			for (index, item) in self.records.enumerated() {
				let tempItem:ListItem = item
				tempItem.itemIndex = index
				self.visibleRecords.append(tempItem)
			}
			
			self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
		}
		
		// Enable/disable the Edit button, depending on if there are any visible items
		self.editButtonItem.isEnabled = self.visibleRecords.count > 0
	}
	
	
	/// After adding a new item to the list, scroll to the bottom of the table view so the new item is visible
	func scrollToBottom() {
		let scrollIndexPath: IndexPath = IndexPath.init(row: self.visibleRecords.count - 1, section: 0)
		self.tableView.scrollToRow(at: scrollIndexPath, at: .bottom, animated: true)
	}
	
	// MARK: - File operation methods
	
	func openFile() {
		let paths: [String] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentsDirectory:String = (paths.first)!
		
		let fileName = self.title! + ".edenlist"
		let writePath = NSURL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileName)
		self.filePath = (writePath?.path)!
		
		print("filePath:: \(filePath)")
		
		if FileManager.default.fileExists(atPath: self.filePath) {
			self.records = self.openFile(filePath: self.filePath)
			self.organizationControl.selectedSegmentIndex = self.visibilityState.rawValue
			
			self.updateVisibleRecords()
		}
	}
	
	func openFile(filePath: String) -> [ListItem] {
		
		var tempRecords = [ListItem]()
		
		if FileManager.default.fileExists(atPath: filePath) {
			if let fileContents = NSDictionary(contentsOfFile: filePath) { 
				print("fileContents: \(fileContents)")
				
				// File records
				if let fileRecords = fileContents["Records"] as? [[String: Any]] {
					for record in fileRecords {
						let newRecord = ListItem(data: record)
						tempRecords.append(newRecord)
					}
				}
				
				// Visibility state
				if let visibility = fileContents["Visibility"] as? Int {
					if let tempVisibility = VisibilityState(rawValue: visibility) {
						self.visibilityState = tempVisibility
					}
				}
			}
		}
		
		return tempRecords
	}
	
	func saveFile() {
	
		// TODO: Create constants/enum/struct, etc. for these keys
		
		let fileContents = NSMutableDictionary() //  Dictionary<AnyHashable, Any>()
		let tempRecords = recordsAsDictionaries()
		
		fileContents["Version"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
		fileContents["Records"] = tempRecords
		fileContents["Visibility"] = self.visibilityState.rawValue
		
		print("fileContents: \(fileContents)")
		
		if filePath.isEmpty == false {
			let success = fileContents.write(toFile: self.filePath, atomically: true)
			if success == false {
				print("There was an error writing to the file \(self.filePath)")
			}
		}
	}
	
	
	/// Parse through the array of ListItems and convert them to NSDictionary objects to be saved out
	///
	/// - Returns: An array of NSDictionary objects
	func recordsAsDictionaries() -> [NSDictionary] {
		
		var tempRecords = [NSDictionary]()
		
		for record in self.records {
			print("record as dictionary: \(record.listItemAsDictionary())")
			let tempRecord = record.listItemAsDictionary()
			tempRecords.append(tempRecord)
		}
		
		return tempRecords
	}

}

// MARK: - EditItemControllerDelegate Methods

extension ListItemsViewController: EditItemControllerDelegate {
	
	func addNewItem(item: ListItem) {

		self.records.append(item)
		self.updateVisibleRecords()
		
		if self.visibleRecords.count > 0 {
			// Scroll to the bottom of the list when a new item has been added.
			// Use a brief delay to ensure the view has appeared again, then scroll to the bottom
			// [self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.1];
			self.perform(#selector(scrollToBottom), with: nil, afterDelay: 0.1)
		}
		
		self.saveFile()
	}
	
	func editItem(item: ListItem, at index: Int) {
		print("editItem: \(item) \(index)")
		
		self.records[index] = item
		self.updateVisibleRecords()
		
		self.saveFile()
	}
}
