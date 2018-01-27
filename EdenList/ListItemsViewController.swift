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

		let paths: [String] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentsDirectory:String = (paths.first)!
		
		let fileName = self.title! + ".edenlist"
		let writePath = NSURL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileName)
		self.filePath = (writePath?.path)!
		
		print("filePath:: \(filePath)")
		
		if FileManager.default.fileExists(atPath: self.filePath) {
			self.records = self.openFile(filePath: self.filePath)
		}
		
        setupUI()
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
		
//		UIApplication *app = [UIApplication sharedApplication];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(applicationWillTerminate:) name: UIApplicationWillTerminateNotification object: app];
	}
	
	// MARK: - IBActions
	
	func shareButtonTapped() {
		let activityItem = self.title // TODO: Change this to the actual file to share
		let shareVC = UIActivityViewController(activityItems: [activityItem], applicationActivities: nil)
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
		print("delete items")
	}

	@IBAction func organizationChanged(_ sender: AnyObject) {
		print("organizationChanged")
	}
	
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.records.count
    }
	
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "listItemReuseID", for: indexPath)

		let item:ListItem = self.records[indexPath.row]
		
        // Configure the cell...
		cell.textLabel?.text = item.itemTitle
		cell.detailTextLabel?.text = item.itemNotes

		cell.imageView?.image = item.itemChecked ? #imageLiteral(resourceName: "checked") : #imageLiteral(resourceName: "unchecked") // #imageLiteral(resourceName: "checked") // UIImage(named: "unchecked")
		// cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		cell.accessibilityHint = NSLocalizedString("Checked", comment: "Checked")
		
        return cell
    }
	
	// MARK: - Table view delegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		let row = indexPath.row
		let item = self.records[row]
		item.itemChecked = !item.itemChecked
		
		self.records[row] = item // update the records with the modified ListItem
		
		self.saveFile()
		
		self.tableView.reloadData()
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
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

	func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
		
		var row: Int = indexPath.row
		
		// let listItem = self.visibleRecords[row] // TODO: Need to use this in the final version
		let listItem = self.records[row]
		
		if self.visibilityState == .unchecked {
			// Send the index of the full records, not just the visible records
//			NSMutableDictionary *rowData = [self.visibleRecords objectAtIndex: row];
//			NSNumber *num = [rowData objectForKey: kIndexKey];
//
//			row = [num intValue];
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
		
		if records.count > 0 {
			self.editButtonItem.isEnabled = false
			self.tableView.setEditing(false, animated: true)
		} else {
			self.tableView.setEditing(editing, animated: animated)
		}
		
	}
	
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
	
	// MARK: - Custom Methods
	
	/*
	- (void) updateVisibleRecords
	{
	[self.visibleRecords removeAllObjects];	// clear out the old contents
	
	if (visibilityState == kShowUncheckedRecords)
	{
	for (int i = 0; i < [self.records count]; i++)
	{
	NSMutableDictionary *rowData = [self.records objectAtIndex: i];
	NSNumber *num = [rowData objectForKey: @"CheckBox"];
	
	if (num != nil && [num boolValue] == NO)
	{
	NSNumber *idx = [NSNumber numberWithInt:i];
	[rowData setObject: idx forKey: @"Index"];
	
	[self.visibleRecords addObject: rowData];
	}
	}
	
	[self.tv reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
	}
	else
	{
	for (int i = 0; i < [self.records count]; i++)
	{
	NSMutableDictionary *rowData = [self.records objectAtIndex: i];
	NSNumber *idx = [NSNumber numberWithInt:i];
	[rowData setObject: idx forKey: @"Index"];
	
	[self.visibleRecords addObject: rowData];
	}
	
	[self.tv reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
	}
	}
	
	*/
	
	func updateVisibleRecords() {
		
		self.visibleRecords.removeAll()
		
		if self.visibilityState == .unchecked { // Unchecked items
			for item in self.records {
				
				var tempItem:ListItem = item.copy() // this may not be correct, might want a pointer to the original item in records array
				let checkedStatus = item.itemChecked
				
				if checkedStatus == false {
					// TODO: Add index value to tempItem
				}
				
				self.visibleRecords.append(tempItem)
			}
			
			self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
			
		} else { // All items
			
			for item in self.records {
				var tempItem:ListItem = item.copy()
				// TODO: Add index value to tempItem
				self.visibleRecords.append(tempItem)
			}
			
			self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
		}
	}
	
	
	/// After adding a new item to the list, scroll to the bottom of the table view so the new item is visible
	func scrollToBottom() {
		let scrollIndexPath: IndexPath = IndexPath.init(row: self.visibleRecords.count - 1, section: 0)
		self.tableView.scrollToRow(at: scrollIndexPath, at: .bottom, animated: true)
	}
	
	// MARK: - File operation methods
	
	func openFile(filePath: String) -> [ListItem] {
		
		var tempRecords = [ListItem]()
		
		if FileManager.default.fileExists(atPath: filePath) {
			if let fileContents = NSDictionary(contentsOfFile: filePath) { //  NSDictionary(contentsOfFile: )
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
					print("visibility: \(visibility)")
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
		fileContents["Visiblity"] = self.visibilityState.rawValue
		
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
		// print("addNewItem: \(item.description())")
		// TODO: Update visible records
		self.records.append(item)
		self.tableView.reloadData()
		
		if self.visibleRecords.count > 0 {
			self.editButtonItem.isEnabled = true
			
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
		self.tableView.reloadData()
		
		// TODO: Update visible records
		
		self.saveFile()
	}
}
