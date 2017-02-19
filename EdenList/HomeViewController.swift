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
		if let listsArray = listManager.lists() as? [String] { // UserDefaults.standard.array(forKey: "Lists") as? [String] {
			self.records = listsArray
		} else {
			self.records = ["Foo", "Bar"] // TODO: Temp code
			// TODO: Display empty view
		}
	}
	
	func saveLists() {
		
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
//		self.records.append("Baz")
//		self.tableView.reloadData()
		
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
		print("Welcome to row \(indexPath.row)")
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


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - NameListViewControllerDelegate Methods

extension HomeViewController: NameListViewControllerDelegate {
	
	func nameListUpdated(with name: String, with row: Int) {
		
	}
	
	func nameListViewCanceled() {
		
	}
}
