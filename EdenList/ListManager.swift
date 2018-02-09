//
//  ListManager.swift
//  EdenList
//
//  Created by Chad Armstrong on 2/16/17.
//  Copyright © 2017 Edenwaith. All rights reserved.
//

import Foundation

class ListManager {
	static let sharedManager = ListManager()
	
	func lists() -> [String] {
		if let availableLists = UserDefaults.standard.array(forKey: "Lists") as? [String] {
			return availableLists
		} else {
			return []
		}
	}
	
	func saveLists(lists: [String]) {
		UserDefaults.standard.set(lists, forKey: "Lists")
		UserDefaults.standard.synchronize()
	}
	
	/// Retrieve and return the name of the most recently view list
	///
	/// - Returns: Name of the most recent list.  If no value exists, an empty string is returned
	func recentList() -> String {
		let recentList = UserDefaults.standard.object(forKey: "Recent List") as? String ?? ""
		return recentList
	}
	
	/// Save a value to the user defaults what was the last viewed list
	/// To clear out the list, set recentList to an empty string
	///
	/// - Parameter recentList: Name of the last viewed list
	func saveRecentList(_ recentList: String) {
		UserDefaults.standard.set(recentList, forKey: "Recent List")
		UserDefaults.standard.synchronize()
	}
	
	func addNewList(url: URL) {
		print("url:: \(url)")
		let fileManager = FileManager.default
		
		// Extract name of file and strip off the file extension
		let fileNameWithExtension = url.lastPathComponent
		let fileName = url.deletingPathExtension().lastPathComponent
		
		// Copy the file to the app's proper Documents folder
		let paths: [String] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentsDirectory:String = (paths.first)!
		
		if let destinationURL = NSURL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileNameWithExtension) {
			print("destinationURL:: \(destinationURL)")
			do {
				try fileManager.copyItem(at: url, to: destinationURL)
			} catch {
				print("Failed to copy \(fileNameWithExtension) to Documents directory")
			}
			
			// Delete the original file from the Inbox folder?
			do {
				try fileManager.removeItem(at: url)
			} catch {
				print("Failed to remove item from Inbox")
			}
			
			// Append the new file name to the list of available files
			var availableLists = self.lists()
			availableLists.append(fileName)
			self.saveLists(lists: availableLists)
		}
	}
	
	// Might want to contemplate this....if this is done, will need to ensure that the itemIndex is updated properly
	func mergeNewList(url: URL) {
		// Extract name of file
		// Open up the pre-existing file with the same name
		// Iterate through the new file and append it's items to the original list
		// Save out the file
		// Delete the original file from the Inbox folder
		
	}
	
	/// Check if a list with the given listName already exists
	///
	/// - Parameter listName: Name of the list being checked
	/// - Returns: True if the listName already exists, False if not
	func listExists(listName: String) -> Bool {
		
		let availableLists = self.lists()
		
		return availableLists.contains(listName)
	}
}
