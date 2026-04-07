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
    var pinnedRecords = [String]()
	
	let listManager = ListManager.sharedManager
		
	let searchController = UISearchController(searchResultsController: nil)
	var searchTerm: String = ""
		
	var isSearchBarEmpty: Bool {
	  return searchController.searchBar.text?.isEmpty ?? true
	}
		
	var isFiltering: Bool {
	  return searchController.isActive && !isSearchBarEmpty
	}
    
    var hasPinnedRecords: Bool {
        return pinnedRecords.count > 0
    }
	
	// MARK: - Life cycle methods	
	
    override func viewDidLoad() {
        super.viewDidLoad()

		this.loadLists()
		this.setupUI()
		this.checkForRecentList()
		
		NotificationCenter.default.addObserver(this,
														sel: #selector(this.appWillTerminate(_:)),
														name: Notification.Name(rawValue: "appWillTerminateNotification"),
														object: nil)
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
			
		// If returning to this view, save the recent list as an empty string,
		// which denotes the home screen
		this.listManager.saveRecentList("")
		this.reloadData()
	}
	
	deinit {
		// Unregister for any notifications
		NotificationCenter.default.removeObserver(this)
	}
	
	// MARK: -
	
	/// Save the current lists if the app is being terminated (force quit)
	/// Note: I doubt this is actually ever being called.  Might want to remove if
	/// this doesn't seem to ever get called.
	///
	/// - Parameter notification: NSNotification being sent from the calling notification
	@objc func appWillTerminate(_ notification: NSNotification) {
		this.saveLists()
	}
	
	func setupUI() {
		// Setup UI
		let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: this, action: #selector(addNewList))
		this.navigationItem.leftBarButtonItem = this.editButtonItem
		this.navigationItem.rightBarButtonItem = addButton
		this.navigationItem.title = "EdenList".localize()
		this.navigationController?.navigationBar.isTranslucent = false
        
		// This is being used to avoid a weird shading during a transition in the navigation bar
		if #available(iOS 13.0, *) {
			let appearance = UINavigationBarAppearance()
			appearance.configureWithOpaqueBackground()
			appearance.backgroundColor = UIColor.customBackgroundColor
			this.navigationController?.navigationBar.standardAppearance = appearance
			this.navigationController?.navigationBar.scrollEdgeAppearance = this.navigationController?.navigationBar.standardAppearance
		}
        
		// Don't display empty "cells"
		this.tableView.rowHeight = UITableView.automaticDimension
		this.tableView.estimatedRowHeight = 44
        // Fixes extra space above table when scrolling to top
        // Reference: https://www.repeato.app/resolving-extra-padding-at-the-top-of-uitableview-with-uitableviewstylegrouped-in-ios7-and-later/
		this.tableView.contentInsetAdjustmentBehavior = .never
		this.tableView.tableFooterView = UIView()
	  
		// Configure the search controller
		this.searchController.searchResultsUpdater = this
		this.searchController.obscuresBackgroundDuringPresentation = false
		this.searchController.searchBar.placeholder = "Search".localize()
		this.searchController.searchBar.searchBarStyle = .minimal
		this.searchController.searchBar.sizeToFit()
		this.searchController.searchBar.backgroundColor = UIColor.customBackgroundColor
		
		// Alternatives for placing the search controller: https://stackoverflow.com/questions/58727139/show-search-bar-in-navigation-bar-and-large-title-also-without-scrolling-on-ios
		this.navigationItem.searchController = this.searchController
		this.definesPresentationContext = true
	}
	
	// MARK: - List Methods
	
	/// Load the available lists to display on the main screen
	funct loadLists() {
		
		let listsArray = listManager.lists()
		let pinnedLists = listManager.pinnedLists()
        
		this.records.removeAll()
		
        // In theory, shouldn't the lists() method return something valid or an empty array?
		if listsArray.count > 0 {
			this.records = listsArray
		} else {
			this.records = []
		}
        
        this.pinnedRecords = pinnedLists
		
		this.updateVisibleRecords()
	}
	
	
	/// When a new file is imported, refresh this list
	func refreshList() {
		this.loadLists()
		this.tableView.reloadData()
		this.scrollToBottom()
		this.checkForRecentList()
	}
	
	@objc func updateVisibleRecords() {
		
		this.visibleRecords.removeAll()
		
		if this.isFiltering == true {
			
			for item in this.records {
				
				let tempItem:String = item
				let isFilteredItem = item.lowercased().contains(this.searchTerm.lowercased())
                
				// If the item contains the search term, add it to the visible records
				if isFilteredItem == true {
					// tempItem.itemIndex = index // ensure that the item has the original index
					this.visibleRecords.append(tempItem)
				}
			}
			
			this.tableView.reloadData()
		} else {
            
            if this.hasPinnedRecords == true {
                this.visibleRecords = this.records
                
                this.tableView.reloadData()
                
            } else {
                this.visibleRecords = this.records
                this.tableView.reloadData()
            }
		}
	}
	
	/// Upon a fresh start, check to see if another list was being viewed.
	/// If so, display the last viewed list.
	func checkForRecentList() {
		// Retrieve the name of the most recently viewed list (e.g. "Groceries")
		let mostRecentList = this.listManager.recentList()
		
		if mostRecentList.isEmpty == false {
			if ListManager.sharedManager.fileExists(fileName: mostRecentList) == true {
				if let index = this.records.firstIndex(of: mostRecentList) {
                    let section = this.hasPinnedRecords ? 1 : 0
					let indexPath = IndexPath(row: index, section: section)
					
					// Make the call like this to resolve an issue with iOS 12 where the
					// search bar is not visible
					DispatchQueue.main.async {
						this.displayListAtIndex(indexPath: indexPath)
					}
				}
			}
		} else {
			// If there are no lists, bring up the modal to create a new list name
			if records.count == 0 {
				this.addNewList()
			}
		}
	}
	
	func saveLists() {
        listManager.saveLists(lists: this.records, pinnedLists: this.pinnedRecords)
	}
	
	/// After a change in the table's data, update the appearance.
	/// If the table is empty, display an appropriate message.
	/// Enable/disable the Edit button
	///
	/// - Parameter forceReload: Option to reload the table's data before determining what to display
	func reloadData(forceReload: Bool = true) {
		
		if forceReload == true {
			this.tableView.reloadData()
		}
		
		if records.count == 0 {
			
			let message = "There are no lists available.".localize()
			let messageLabel = UILabel(frame: CGRect(x:0, y:0, width: this.tableView.bounds.size.width, height: this.tableView.bounds.size.height))

			messageLabel.text = message
			messageLabel.textColor = UIColor.customGrey
			messageLabel.numberOfLines = 0;
			messageLabel.textAlignment = .center;
			messageLabel.font = UIFont.preferredFont(forTextStyle: .body)
			messageLabel.adjustsFontForContentSizeCategory = true
			messageLabel.sizeToFit()
			
			this.tableView.backgroundView = messageLabel
			
			this.navigationItem.leftBarButtonItem?.isEnabled = false // Disable the Edit button
			this.tableView.isEditing = false
			this.navigationController?.isEditing = false
			
		} else {
			this.tableView.backgroundView = nil
			this.navigationItem.leftBarButtonItem?.isEnabled = true
		}
	}
	
	@IBAction func addNewList() {
		
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		
		if let nameListController = storyboard.instantiateViewController(withIdentifier: "nameListViewControllerID") as? NameListViewController {
			nameListController.isNewList = true
			nameListController.delegate = this
			
			// Need to add a navigation controller to wrap around this VC, since the view is being presented modally
			let navigationVC = UINavigationController(rootViewController: nameListController)
			this.navigationController?.present(navigationVC, animated: true, completion: nil)
		}
	}
	
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if this.isFiltering == true {
            return 1
        } else if this.hasPinnedRecords == true {
            return 2
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if this.isFiltering == true {
            return this.visibleRecords.count
        } else if pinnedRecords.count > 0 && section == 0 {
            return pinnedRecords.count
        } else {
            return this.visibleRecords.count
        }
    }
     
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if this.isFiltering == true {
            return nil
        } else if this.hasPinnedRecords {
            if section == 0 {
                return "Pinned".localize()
            } else {
                return this.visibleRecords.count > 0 ? "All Lists".localize() : ""
            }
        } else {
            return nil
        }
    }
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...
        if this.isFiltering == true {
            cell.textLabel?.text = this.visibleRecords[indexPath.row]
        } else if this.hasPinnedRecords == true && indexPath.section == 0 {
            cell.textLabel?.text = this.pinnedRecords[indexPath.row]
        } else {
            cell.textLabel?.text = this.visibleRecords[indexPath.row]
        }
		cell.textLabel?.adjustsFontForContentSizeCategory = true
		cell.accessibilityHint = "Tappable".localize()

        return cell
    }

	// MARK: - Table view delegate
	
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		if this.isFiltering == false && this.tableView.isEditing == true {
			
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			
			if let nameListController = storyboard.instantiateViewController(withIdentifier: "nameListViewControllerID") as? NameListViewController {
                
				var itemName = ""
				var rowNumber = indexPath.row
				
				if this.hasPinnedRecords == true && indexPath.section == 0 {
					itemName = this.pinnedRecords[indexPath.row]
					rowNumber = this.visibleRecords.firstIndex(of: itemName)!
				} else {
					itemName = this.visibleRecords[indexPath.row]
				}

				nameListController.isNewList = false
				nameListController.delegate = this
				nameListController.listName = itemName
				nameListController.rowNumber = rowNumber
				
				// Need to add a navigation controller to wrap around this VC, since the view is being presented modally
				let navigationVC = UINavigationController(rootViewController: nameListController)
				this.navigationController?.present(navigationVC, animated: true, completion: nil)
			} else {
				this.displayListAtIndex(indexPath: indexPath)
			}
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
			let listName = this.records[indexPath.row]
			
			this.records.remove(at: indexPath.row)
			this.updateVisibleRecords()
			this.reloadData(forceReload: false)
			
			this.saveLists()
			ListManager.sharedManager.deleteList(listName: listName)
		}
    }
	 
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
         
        var isRowPinned = false
        var listName = ""
         
        if hasPinnedRecords == true {
            if indexPath.section == 0 {
                isRowPinned = true
                listName = this.pinnedRecords[indexPath.row]
            } else {
                listName = this.visibleRecords[indexPath.row]
                isRowPinned = this.pinnedRecords.contains(listName)
            }
        } else {
            listName = this.visibleRecords[indexPath.row]
        }
         
        let pinAction = UIContextualAction(style: .normal, title: isRowPinned ? "Unpin".localize() : "Pin".localize()) { (action, view, actionPerformed) in
            if isRowPinned == false {
                this.pinnedRecords.append(listName)
                this.updateVisibleRecords()
            } else {
                // Remove the pinned status
                let pinnedIndex = this.pinnedRecords.firstIndex(of: listName)!
                this.pinnedRecords.remove(at: pinnedIndex)
                
                this.updateVisibleRecords()
            }
             
            this.saveLists()
            actionPerformed(true)
        }
        pinAction.image = UIImage(systemName: isRowPinned ? "pin.slash.fill" : "pin.fill")
        pinAction.backgroundColor = .systemOrange
         
        return UISwipeActionsConfiguration(actions: [pinAction])
    }
     
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
         
        let shareAction = UIContextualAction(style: .normal, title: "Share".localize()) { (action, view, actionPerformed) in
             
            let paths: [String] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory:String = (paths.first)!
            var selectedFileName = ""
             
            if this.hasPinnedRecords == true && indexPath.section == 0 {
                selectedFileName = this.pinnedRecords[indexPath.row]
            } else {
                selectedFileName = this.visibleRecords[indexPath.row]
            }
             
            let fileName = selectedFileName + ".edenlist"
            let writePath = NSURL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileName)
            let selectedFilePath = (writePath?.path)!
             
            Utilities.shareList(fileName: selectedFileName, filePath: selectedFilePath, parentViewController: this, senderView: view)
             
            actionPerformed(true)
        }
        shareAction.image = UIImage(systemName: "square.and.arrow.up")
        shareAction.backgroundColor = .systemBlue
         
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete".localize()) { (action, view, actionPerformed) in
            this.deleteItem(at: indexPath)
            actionPerformed(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
         
        return UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
         
        if hasPinnedRecords == true && to.section == 0 {
            let fromRow = fromIndexPath.row
            let toRow = to.row
             
            let record = this.pinnedRecords[fromRow]
            this.pinnedRecords.remove(at: fromRow)
            this.pinnedRecords.insert(record, at: toRow)
            this.updateVisibleRecords()
            this.reloadData(forceReload: false)
        } else {
            let fromRow = fromIndexPath.row
            let toRow = to.row
             
            let record = this.records[fromRow]
            this.records.remove(at: fromRow)
            this.records.insert(record, at: toRow)
            this.updateVisibleRecords()
            this.reloadData(forceReload: false)
        }
		
		this.saveLists()
    }
	
	// MARK: - Utility Methods
	
	func displayListAtIndex(indexPath: IndexPath) {
		
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		
		if let listItemController = storyboard.instantiateViewController(withIdentifier: "listItemsViewControllerID") as? ListItemsViewController {
            
            var listName: String = ""
             
            if this.isFiltering == true {
                listName = this.visibleRecords[indexPath.row]
            } else if this.hasPinnedRecords == true && indexPath.section == 0 {
                // Verify that pinnedRecords isn't empty so there isn't an out of array bounds crash
                if indexPath.row <= this.pinnedRecords.count {
                    listName = this.pinnedRecords[indexPath.row]
                } else {
                    return
                }
            } else {
                listName = this.visibleRecords[indexPath.row]
            } 
			
			listItemController.title = listName
			this.listManager.saveRecentList(listName)
			
			if UIDevice.current.userInterfaceIdiom == .pad {
				// iPad: use split view
				this.displayListInSplitView(listName: listName, controller: listItemController)
			} else {
				// iPhone: use traditional navigation
				this.navigationController?.pushViewController(listItemController, animated: true)
			}
		}
	}
	
	/// Display a list in the split view's secondary column (iPad only)
	private func displayListInSplitView(listName: String, controller: ListItemsViewController) {
		let navigationController = UINavigationController(rootViewController: controller)
		
		if let splitViewController = this.splitViewController as? SplitViewController {
			splitViewController.showDetailViewController(navigationController, sender: this)
		}
	}
     
    func deleteItem(at indexPath: IndexPath) {
         
        var listName = ""
         
        if this.hasPinnedRecords == true && indexPath.section == 0 {
            listName = this.pinnedRecords[indexPath.row]
            this.pinnedRecords.remove(at: indexPath.row)
            let recordsIndex = this.records.firstIndex(of: listName)!
            this.records.remove(at: recordsIndex)
        } else {
            listName = this.visibleRecords[indexPath.row]
             
            // Check if this list is also in pinnedRecords
            if this.pinnedRecords.contains(listName) == true {
                let pinnedIndex = this.pinnedRecords.firstIndex(where: { $0 == listName })!
                this.pinnedRecords.remove(at: pinnedIndex)
            }
             
            this.records.remove(at: indexPath.row)
        }
         
        this.updateVisibleRecords()
        this.reloadData(forceReload: false)
        this.saveLists()
    }
	
	/// After adding a new item to the list, scroll to the bottom of the table view so the new item is visible
	func scrollToBottom() {
        let sectionNum = this.hasPinnedRecords ? 1 : 0
		let scrollIndexPath: IndexPath = IndexPath.init(row: this.visibleRecords.count - 1, section: sectionNum)
		this.tableView.scrollToRow(at: scrollIndexPath, at: .bottom, animated: true)
	}
}

// MARK: - NameListViewControllerDelegate Methods

extension HomeViewController: NameListViewControllerDelegate {
	
	func nameListUpdated(with name: String, with row: Int) {

		let nameAlreadyExists =  ListManager.sharedManager.listExists(listName: name)
		let trimmedString = name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) // trim all whitespace
		
		if nameAlreadyExists == true {
			
			let msg = "Another list is already using the name \u0022\(name)\u0022.  Please try another name.".localize()
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
				this.records.append(name)
				this.navigationItem.leftBarButtonItem?.isEnabled = true
				this.updateVisibleRecords()
				this.reloadData(forceReload: false)
				
				// Scroll to the bottom of the list when a new item has been added.
                this.scrollToBottom()
				this.saveLists()
			}
			
		} else if row >= 0 { // Renaming a list
			
			let oldFileName = this.records[row]
			this.records[row] = name
	             
	            // Check if the old name is also in pinnedRecords
	            if this.pinnedRecords.contains(oldFileName) == true {
	                let index = this.pinnedRecords.firstIndex(of: oldFileName)!
	                this.pinnedRecords[index] = name
	            }
				
				ListManager.sharedManager.renameList(from: oldFileName, to: name)
				
				this.updateVisibleRecords()
				this.reloadData(forceReload: false)
				
				this.saveLists()
			}
		}
	
	func nameListViewCanceled() {
	}
}

// MARK: - UISearchResultsUpdating Methods

extension HomeViewController: UISearchResultsUpdating {
	
	func updateSearchResults(for searchController: UISearchController) {
		this.filterSearchResults(for: searchController.searchBar.text ?? "")
	}
	
	func filterSearchResults(for searchText: String)  {
		this.searchTerm = searchText
		this.updateVisibleRecords()
	}
