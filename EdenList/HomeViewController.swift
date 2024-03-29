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
	var visibleRecords = [String]()
	
	let listManager = ListManager.sharedManager
	
	let searchController = UISearchController(searchResultsController: nil)
	var searchTerm: String = ""
	
	var isSearchBarEmpty: Bool {
	  return searchController.searchBar.text?.isEmpty ?? true
	}
	
	var isFiltering: Bool {
	  return searchController.isActive && !isSearchBarEmpty
	}
	
	// MARK: - Life cycle methods
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.loadLists()
		self.setupUI()
		self.checkForRecentList()
		
		NotificationCenter.default.addObserver(self,
											   selector: #selector(self.appWillTerminate(_:)),
											   name: Notification.Name(rawValue: "appWillTerminateNotification"),
											   object: nil)
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// If returning to this view, save the recent list as an empty string,
		// which denotes the home screen
		self.listManager.saveRecentList("")
		self.reloadData()
	}
	
	deinit {
		// Unregister for any notifications
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: -
	
	/// Save the current lists if the app is being terminated (force quit)
	/// Note: I doubt this is actually ever being called.  Might want to remove if
	/// this doesn't seem to ever get called.
	///
	/// - Parameter notification: NSNotification being sent from the calling notification
	@objc func appWillTerminate(_ notification: NSNotification) {
		self.saveLists()
	}
	
	func setupUI() {
		// Setup UI
		let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewList))
		self.navigationItem.leftBarButtonItem = self.editButtonItem
		self.navigationItem.rightBarButtonItem = addButton
		self.navigationItem.title = "EdenList".localize()
		self.navigationController?.navigationBar.isTranslucent = false
		
		// This is being used to avoid a weird shading during a transition in the navigation bar
		if #available(iOS 13.0, *) {
			let appearance = UINavigationBarAppearance()
			appearance.configureWithOpaqueBackground()
			appearance.backgroundColor = UIColor.customBackgroundColor
			self.navigationController?.navigationBar.standardAppearance = appearance
			self.navigationController?.navigationBar.scrollEdgeAppearance = self.navigationController?.navigationBar.standardAppearance
		}
		
		// Don't display empty "cells"
		self.tableView.rowHeight = UITableView.automaticDimension
		self.tableView.estimatedRowHeight = 44
		self.tableView.tableFooterView = UIView()
		
		// Configure the search controller
		self.searchController.searchResultsUpdater = self
		self.searchController.obscuresBackgroundDuringPresentation = false
		self.searchController.searchBar.placeholder = "Search".localize()
		self.searchController.searchBar.searchBarStyle = .minimal
		self.searchController.searchBar.sizeToFit()
		self.searchController.searchBar.backgroundColor = UIColor.customBackgroundColor
		
		// Alternatives for placing the search controller: https://stackoverflow.com/questions/58727139/show-search-bar-in-navigation-bar-and-large-title-also-without-scrolling-on-ios
		self.navigationItem.searchController = self.searchController
		self.definesPresentationContext = true
	}
	
	// MARK: - List Methods
	
	/// Load the available lists to display on the main screen
	func loadLists() {
		
		let listsArray = listManager.lists()
		
		self.records.removeAll()
		
		if listsArray.count > 0 {
			self.records = listsArray
		} else {
			self.records = []
		}
		
		self.updateVisibleRecords()
	}
	
	
	/// When a new file is imported, refresh this list
	func refreshList() {
		self.loadLists()
		self.tableView.reloadData()
		self.scrollToBottom()
		self.checkForRecentList()
	}
	
	@objc func updateVisibleRecords() {
		
		self.visibleRecords.removeAll()
		
		if self.isFiltering == true {
			
			for item in self.records {

				let tempItem:String = item
				let isFilteredItem = item.lowercased().contains(self.searchTerm.lowercased())

				// If the item contains the search term, add it to the visible records
				if isFilteredItem == true {
					// tempItem.itemIndex = index // ensure that the item has the original index
					self.visibleRecords.append(tempItem)
				}
			}
			
			self.tableView.reloadData()
		} else {
			self.visibleRecords = self.records
			self.tableView.reloadData()
		}
	}
	
	/// Upon a fresh start, check to see if another list was being viewed.
	/// If so, display the last viewed list.
	func checkForRecentList() {
		// Retrieve the name of the most recently viewed list (e.g. "Groceries")
		let mostRecentList = self.listManager.recentList()
		
		if mostRecentList.isEmpty == false {
			if ListManager.sharedManager.fileExists(fileName: mostRecentList) == true {
				if let index = self.records.firstIndex(of: mostRecentList) {
					let indexPath = IndexPath(row: index, section: 0)
					
					// Make the call like this to resolve an issue with iOS 12 where the
					// search bar is not visible
					DispatchQueue.main.async {
						self.displayListAtIndex(indexPath: indexPath)
					}
				}
			}
		} else {
			// If there are no lists, bring up the modal to create a new list name
			if records.count == 0 {
				self.addNewList()
			}
		}
	}
	
	func saveLists() {
		listManager.saveLists(lists: self.records)
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
			
			let message = "There are no lists available.".localize()
			let messageLabel = UILabel(frame: CGRect(x:0, y:0, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height))

			messageLabel.text = message
			messageLabel.textColor = UIColor.customGrey
			messageLabel.numberOfLines = 0;
			messageLabel.textAlignment = .center;
			messageLabel.font = UIFont.preferredFont(forTextStyle: .body)
			messageLabel.adjustsFontForContentSizeCategory = true
			messageLabel.sizeToFit()
			
			self.tableView.backgroundView = messageLabel
			
			self.navigationItem.leftBarButtonItem?.isEnabled = false // Disable the Edit button
			self.tableView.isEditing = false
			self.navigationController?.isEditing = false
			
		} else {
			self.tableView.backgroundView = nil
			self.navigationItem.leftBarButtonItem?.isEnabled = true
		}
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
        return self.visibleRecords.count
    }

	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...
		cell.textLabel?.text = self.visibleRecords[indexPath.row]
		cell.textLabel?.adjustsFontForContentSizeCategory = true
		cell.accessibilityHint = "Tappable".localize()

        return cell
    }

	// MARK: - Table view delegate
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		if self.isFiltering == false && self.tableView.isEditing == true {
			
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			
			if let nameListController = storyboard.instantiateViewController(withIdentifier: "nameListViewControllerID") as? NameListViewController {
				let itemName = self.visibleRecords[indexPath.row]
				nameListController.isNewList = false
				nameListController.delegate = self
				nameListController.listName = itemName
				nameListController.rowNumber = indexPath.row
				
				// Need to add a navigation controller to wrap around this VC, since the view is being presented modally
				let navigationVC = UINavigationController(rootViewController: nameListController)
				// TODO: In a future update, add any additional code which might be needed for larger devices (iPad, iPhone Plus, etc.)
				// to display this as a modal pop over instead of a new view covering the entire screen.
				self.navigationController?.present(navigationVC, animated: true, completion: nil)
			}
		} else {
			self.displayListAtIndex(indexPath: indexPath)
		}
	}
	
	// MARK: - Edit Rows
	
	// Override to support conditional editing of the table view.
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		if isFiltering == true {
			return false
		} else {
			return true
		}
	}
	
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		
        if editingStyle == .delete {
			
            // Delete the row from the data source
			let listName = self.records[indexPath.row]
			
			self.records.remove(at: indexPath.row)
			self.updateVisibleRecords()
			self.reloadData(forceReload: false)

			self.saveLists()
			ListManager.sharedManager.deleteList(listName: listName)
        }
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		let fromRow = fromIndexPath.row
		let toRow = to.row
		
		let record = self.records[fromRow]
		self.records.remove(at: fromRow)
		self.records.insert(record, at: toRow)
		self.updateVisibleRecords()
		self.reloadData(forceReload: false)
		
		self.saveLists()
    }
	
	// MARK: - Utility Methods
	
	func displayListAtIndex(indexPath: IndexPath) {
		
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		
		if let listItemController = storyboard.instantiateViewController(withIdentifier: "listItemsViewControllerID") as? ListItemsViewController {
		
			let listName = self.visibleRecords[indexPath.row]
			listItemController.title = listName
			self.listManager.saveRecentList(listName)
			
			self.navigationController?.pushViewController(listItemController, animated: true)
		}
	}
	
	/// After adding a new item to the list, scroll to the bottom of the table view so the new item is visible
	func scrollToBottom() {
		let scrollIndexPath: IndexPath = IndexPath.init(row: self.visibleRecords.count - 1, section: 0)
		self.tableView.scrollToRow(at: scrollIndexPath, at: .bottom, animated: true)
	}
}

// MARK: - NameListViewControllerDelegate Methods

extension HomeViewController: NameListViewControllerDelegate {
	
	func nameListUpdated(with name: String, with row: Int) {

		let nameAlreadyExists =  ListManager.sharedManager.listExists(listName: name)
		let trimmedString = name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) // trim all whitespace
		
		if nameAlreadyExists == true {
			
			let msg = "Another list is already using the name \"\(name)\".  Please try another name.".localize()
			let alert = UIAlertController(title: "Warning".localize(), message: msg, preferredStyle: .alert)
			let defaultAction = UIAlertAction(title: "OK".localize(), style: .default, handler: nil)
			alert.addAction(defaultAction)
			
			present(alert, animated: true, completion: nil)
			
		} else if trimmedString.isEmpty == true { // Empty name
			
			let msg = "The list name cannot be blank.  Please enter in a name for your list".localize()
			let alert = UIAlertController(title: "Warning".localize(), message: msg, preferredStyle: .alert)
			let defaultAction = UIAlertAction(title: "OK".localize(), style: .default, handler: nil)
			alert.addAction(defaultAction)
			
			present(alert, animated: true, completion: nil)
			
		} else if row < 0 { // New list
			
			if nameAlreadyExists == false {
				self.records.append(name)
				self.navigationItem.leftBarButtonItem?.isEnabled = true
				self.updateVisibleRecords()
				self.reloadData(forceReload: false)
				
				// Scroll to the bottom of the list when a new item has been added.
				let scrollIndexPath = IndexPath(row: self.records.count - 1, section: 0) // [NSIndexPath indexPathForRow:([records count]-1) inSection:0];
				self.tableView.scrollToRow(at: scrollIndexPath, at: .top, animated: true)
				
				self.saveLists()
			}
			
		} else if row >= 0 { // Renaming a list
			
			let oldFileName = self.records[row]
			self.records[row] = name
			
			ListManager.sharedManager.renameList(from: oldFileName, to: name)
			
			self.updateVisibleRecords()
			self.reloadData(forceReload: false)
			
			self.saveLists()
		}
	}
	
	func nameListViewCanceled() {
	}
}

// MARK: - UISearchResultsUpdating Methods

extension HomeViewController: UISearchResultsUpdating {
	
	func updateSearchResults(for searchController: UISearchController) {
		self.filterSearchResults(for: searchController.searchBar.text ?? "")
	}
	
	func filterSearchResults(for searchText: String)  {
		self.searchTerm = searchText
		self.updateVisibleRecords()
	}
}
