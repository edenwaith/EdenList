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
	case filtered	= 2
	
	init?(rawValue: Int) {
		switch rawValue {
		case 0:  self = .all
		case 1:  self = .unchecked
		case 2:  self = .filtered
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

struct Constants {
	struct File {
		static let Version    = "Version"
		static let Records    = "Records"
		static let Visibility = "Visibility"
	}
}

class ListItemsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var organizationControl: UISegmentedControl!
	
	var records = [ListItem]()
	var visibleRecords = [ListItem]()
	
	var filePath: String = ""
	var visibilityState: VisibilityState = .all
	
	let searchController = UISearchController(searchResultsController: nil)
    var searchTerm: String = ""
    
	var isSearchBarEmpty: Bool {
	  return searchController.searchBar.text?.isEmpty ?? true
	}
	
	var isFiltering: Bool {
	  return searchController.isActive && !isSearchBarEmpty
	}
	
	// MARK: - View Life Cycle
	
    override func viewDidLoad() {
        super.viewDidLoad()

		// Reference to reorder rows using a long press
		// https://www.freshconsulting.com/create-drag-and-drop-uitableview-swift/
		// https://github.com/Task-Hero/TaskHero-iOS/blob/master/TaskHero/HomeViewController.swift
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
		actionButtonItem.style = UIBarButtonItem.Style.plain
		
		self.navigationItem.rightBarButtonItems = [self.editButtonItem, actionButtonItem]
		
		// Set up the table view
		self.tableView.rowHeight = UITableView.automaticDimension
		self.tableView.estimatedRowHeight = 44
		self.tableView.tableFooterView = UIView()
		
		// Configure the search controller
		self.searchController.searchResultsUpdater = self
		self.searchController.dimsBackgroundDuringPresentation = false
		self.searchController.searchBar.placeholder = "Search".localize()
		self.definesPresentationContext = true
		self.tableView.tableHeaderView = searchController.searchBar
		
		// This is 44.0 on iOS 10, but 56.0 on iOS 11 and later due to the search bar being larger
		let searchBarHeight = self.searchController.searchBar.frame.size.height
		
		// Hide the search bar upon initial load of this screen
		if #available(iOS 11.0, *) {
			// Change the offset w/i the dispatch queue so this gets properly adjusted on iPhone X-style displays
			// Reference: https://stackoverflow.com/a/40077398
			DispatchQueue.main.async {
				let offset = CGPoint.init(x: 0, y: searchBarHeight)
				self.tableView.setContentOffset(offset, animated: false)
			}
		} else {
			// For iOS 10, because the above version creates and odd offset for the tableview
			self.tableView.contentOffset = CGPoint(x: 0, y: searchBarHeight)
		}
	}
	
	// MARK: - IBActions
	
	@objc func shareButtonTapped(_ sender: UIBarButtonItem) {
		
		let fileTitle = self.title ?? ""
		let fileURL = NSURL(fileURLWithPath: self.filePath)
		
		var htmlContent = ""
		
		// Retrieve the print_template.html file and put into a string
		let templatePath = Bundle.main.path(forResource: "print_template", ofType: "html")
		
		do {
			htmlContent = try String(contentsOfFile:templatePath!, encoding: String.Encoding.utf8)
			// Swap out the title with the name of the file to print
			htmlContent = htmlContent.replacingOccurrences(of: "__LIST_TITLE__", with: fileTitle)
			
			var itemsHTML = ""
			
			// Loop through the records and construct an HTML table for printing
			for item in self.records {
				let checkedOption: String = item.itemChecked ? "checked " : ""
				let itemTemplate = """
					<tr>
						<td><input type="checkbox" \(checkedOption)/></td>
						<td>
							<h4>\(item.itemTitle)</h4>
							<h5>\(item.itemNotes)</h4>
						</td>
					</tr>
				"""
				
				itemsHTML += itemTemplate
			}
			
			htmlContent = htmlContent.replacingOccurrences(of: "__LIST_ITEMS__", with: itemsHTML)
			
		} catch _ as NSError {
			
		}
		
		let printInfo = UIPrintInfo(dictionary:nil)
		printInfo.outputType = UIPrintInfo.OutputType.general
		printInfo.jobName = fileTitle
		printInfo.orientation = .portrait
		printInfo.duplex = .longEdge
				
		let formatter = UIMarkupTextPrintFormatter(markupText: htmlContent)
		formatter.perPageContentInsets = UIEdgeInsets(top: 36, left: 36, bottom: 36, right: 36)
		
		let excludedTypes:[UIActivity.ActivityType] = [.postToFacebook, .postToTwitter, .postToVimeo, .postToWeibo, .postToFlickr, .addToReadingList, .assignToContact, .saveToCameraRoll]
		let shareVC = UIActivityViewController(activityItems: [fileTitle, fileURL, printInfo, formatter], applicationActivities: nil)

		shareVC.excludedActivityTypes = excludedTypes
		shareVC.setValue(fileTitle, forKey: "subject")
		
		if let popoverPresentationController = shareVC.popoverPresentationController {
			popoverPresentationController.barButtonItem = sender
		}
		
		// If displaying the share sheet is slow, use the dispatch queue
		//DispatchQueue.main.async() {
			self.present(shareVC, animated: true, completion: nil)
		//}
		
	}
	
	@IBAction func addItem(_ sender: AnyObject) {
		
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		
		if let editItemController = storyboard.instantiateViewController(withIdentifier: "editItemViewControllerID") as? EditItemViewController {
			editItemController.title = "New Item".localize()
			editItemController.delegate = self
			
			// This corrects an edge case where the last item was deleted while
			// the tableView was in edit mode, but when a new item is added, the
			// table is still in edit mode, even though it was previously set to
			// not be in edit mode.
			if self.records.count <= 0 {
				self.tableView.isEditing = false
			}
			
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
		alert.addAction(UIAlertAction(title: "Cancel".localize(), style: UIAlertAction.Style.cancel, handler: nil))
		
		if let popoverPresentationController = alert.popoverPresentationController {
			// Pop over for larger screens (e.g. iPad)
			popoverPresentationController.barButtonItem = (sender as! UIBarButtonItem)
		}
		
		// Display the action sheet
		present(alert, animated: true) {}
	}

	/// The All/Unchecked UISegmentedControll was tapped.  Change the visibility state and refresh the table
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
		cell.textLabel?.adjustsFontForContentSizeCategory = true
		cell.detailTextLabel?.text = item.itemNotes
		cell.detailTextLabel?.adjustsFontForContentSizeCategory = true

		cell.imageView?.image = item.itemChecked ? #imageLiteral(resourceName: "checked") : #imageLiteral(resourceName: "unchecked")
		cell.accessoryType =  .detailDisclosureButton
		cell.accessibilityHint = "Checked".localize()
		
        return cell
    }
	
	// MARK: - Table view delegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		if self.isFiltering == true { // Filtered/Search results
			
			let row = indexPath.row
			let item = self.visibleRecords[row]
			let tempIndex = item.itemIndex
			item.itemChecked = !item.itemChecked
			
			self.records[tempIndex] = item
			
			self.saveFile()
			self.updateVisibleRecords()
			
		} else if self.visibilityState == .all {
			
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
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		
        if editingStyle == .delete {
            // Delete the row from the data source
			let row = indexPath.row
			
            // When searching or displaying only the Unchecked items
            if self.isFiltering == true || self.visibilityState == .unchecked {
				
				let selectedObject = self.visibleRecords[row]
				let originalIndex = selectedObject.itemIndex
				
				if originalIndex >= 0 {
					self.records.remove(at: originalIndex)
				}
				
				self.updateVisibleRecords()
                
			} else if self.visibilityState == .all {
                
                self.records.remove(at: row)
                self.updateVisibleRecords()
                
            }
			
            // If there are no visible Unchecked records to display, disable the Edit button
            if self.visibleRecords.count <= 0 && self.isFiltering == false {
				self.tableView.setEditing(false, animated: true)
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
		
        // Select the correct item for filtered and unchecked views
        if self.isFiltering == true || self.visibilityState == .unchecked {
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
			self.tableView.setEditing(false, animated: animated)
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
		if self.isFiltering == true {
			return false
		} else if self.visibilityState == .all {
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
			messageLabel.textColor = UIColor.customGrey
			messageLabel.numberOfLines = 0;
			messageLabel.textAlignment = .center;
			messageLabel.font = UIFont.preferredFont(forTextStyle: .body)
			messageLabel.adjustsFontForContentSizeCategory = true
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
	
	// Fun side note: The equivalent Objective-C method was 20 lines of code, compared to about a quarter of that here
	func deleteCheckedItems() {
		// A nice little trick learned from the Embracing Algorithms WWDC18 video
		// https://developer.apple.com/videos/play/wwdc2018/223/
		self.records.removeAll { $0.itemChecked }
		self.updateVisibleRecords()
		self.saveFile()
	}
	
	func deleteUncheckedItems() {
		self.records.removeAll { $0.itemChecked == false }
		self.updateVisibleRecords()
		self.saveFile()
	}
	
	@objc func updateVisibleRecords() {
		
		self.visibleRecords.removeAll()
		
		if self.isFiltering == true {
            
            for (index, item) in self.records.enumerated() {

                let tempItem:ListItem = item
                let isFilteredItem = item.itemTitle.lowercased().contains(self.searchTerm.lowercased())

                // If the item contains the search term, add it to the visible records
                if isFilteredItem == true {
                    tempItem.itemIndex = index // ensure that the item has the original index
                    self.visibleRecords.append(tempItem)
                }
            }
            
			self.tableView.reloadData()
		}
		else if self.visibilityState == .unchecked { // Unchecked items
			// I initially tried using a filter function, but it caused a bug
			// if an item was quickly tapped multiple times, which would
			// duplicate an item.
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
			
			// With really long lists, if the refreshed list has its first cell not at the top
			// or out of the screen's view, scroll the table to the top.
			// If this is not done, then the screen looks blank until the user scrolls
			if self.tableView.contentOffset.y < 0 {
				self.tableView.setContentOffset(.zero, animated: true)
			}
			
		} else { // All items
			
			self.visibleRecords = self.records
			
			// Do not use reloadSections since it causes the table to jump and flicker
			self.tableView.reloadData()
		}
		
		self.reloadData(forceReload: false)
	}
	
	
	/// After adding a new item to the list, scroll to the bottom of the table view so the new item is visible
	@objc func scrollToBottom() {
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
				
				// File records
				if let fileRecords = fileContents[Constants.File.Records] as? [[String: Any]] {
					for record in fileRecords {
						let newRecord = ListItem(data: record)
						tempRecords.append(newRecord)
					}
				}
				
				// Visibility state
				if let visibility = fileContents[Constants.File.Visibility] as? Int {
					if let tempVisibility = VisibilityState(rawValue: visibility) {
						self.visibilityState = tempVisibility
					}
				}
			}
		}
		
		return tempRecords
	}
	
	func saveFile() {
		
		let fileContents = NSMutableDictionary()
		let tempRecords = recordsAsDictionaries()
		
		fileContents[Constants.File.Version] = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
		fileContents[Constants.File.Records] = tempRecords
		fileContents[Constants.File.Visibility] = self.visibilityState.rawValue
		
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
			let tempRecord = record.listItemAsDictionary()
			tempRecords.append(tempRecord)
		}
		
		return tempRecords
	}

}

// MARK: - EditItemControllerDelegate Methods

extension ListItemsViewController: EditItemControllerDelegate {
	
	func addNewItem(item: ListItem) {

		item.itemIndex = self.records.count // Set an itemIndex for this new list item
		
		self.records.append(item)
		self.updateVisibleRecords()
		
		if self.visibleRecords.count > 0 {
			// Scroll to the bottom of the list when a new item has been added.
			// Use a brief delay to ensure the view has appeared again, then scroll to the bottom
			self.perform(#selector(scrollToBottom), with: nil, afterDelay: 0.1)
		}
		
		self.saveFile()
	}
	
	func editItem(item: ListItem, at index: Int) {
		
		self.records[index] = item
		
		self.updateVisibleRecords()
		self.saveFile()
	}
}

// MARK: - UISearchResultsUpdating Methods

extension ListItemsViewController: UISearchResultsUpdating {
	
	func updateSearchResults(for searchController: UISearchController) {
		self.filterSearchResults(for: searchController.searchBar.text ?? "")
	}
	
	func filterSearchResults(for searchText: String)  {
        self.searchTerm = searchText
		self.updateVisibleRecords()
	}
}
