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
	
	
	/// Import a new list, add to the available lists and copy into the app's documents directory
	///
	/// - Parameter url: URL path of the temporary file, initially stored in the Inbox directory
	func addNewList(url: URL) {

		let fileManager = FileManager.default
		
		// Extract name of file and strip off the file extension
		let fileNameWithExtension = url.lastPathComponent
		let fileName = url.deletingPathExtension().lastPathComponent
		
		// Copy the file to the app's proper Documents folder
		let paths: [String] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentsDirectory:String = (paths.first)!
		
		if let destinationURL = NSURL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileNameWithExtension) {
			
			do {
				try fileManager.moveItem(at: url, to: destinationURL)
			} catch {
				print("Could not move paths")
			}
			
			// Append the new file name to the list of available files
			var availableLists = self.lists()
			availableLists.append(fileName)
			
			self.saveLists(lists: availableLists)
			self.saveRecentList(fileName)
		}
	}
	
	
	/// If a list already exists, rename and add the new list.
	///
	/// - Parameter url: URL path of the temporary file, initially stored in the Inbox directory
	func addAndRenameNewList(url: URL) {
		
		let listName = url.deletingPathExtension().lastPathComponent
		var newListName = ""
		var indexNum: Int = 1
		
		// If the new file has the same name as an existing file, rename the new file
		// Following the macOS pattern, append a " 2" to the end of the file name.  If
		// the new file name also exists, continue to increment the index number until
		// a unique name is available.
		repeat {
			indexNum += 1
			newListName = "\(listName) \(indexNum)"
		} while ListManager.sharedManager.listExists(listName: newListName) == true
		
		let newFileName = newListName + ".edenlist"
		let fileManager = FileManager.default
		
		// Copy the file to the app's proper Documents folder
		let paths: [String] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentsDirectory:String = (paths.first)!
		
		if let destinationURL = NSURL(fileURLWithPath: documentsDirectory).appendingPathComponent(newFileName) {
		
			do {
				try fileManager.moveItem(at: url, to: destinationURL)
			} catch {
				print("Could not move paths")
			}
			
			// Append the new file name to the list of available files
			var availableLists = self.lists()
			availableLists.append(newListName)
			
			self.saveLists(lists: availableLists)
			self.saveRecentList(newListName)
		}
	}
	
	// Currently unused stub method
	func mergeNewList(url: URL) {
		// Extract name of file
		// Open up the pre-existing file with the same name
		// Iterate through the new file and append it's items to the original list
		// Update itemIndex accordingly for each item
		// Save out the file
		// Delete the original file from the Inbox folder
		
	}
	
	/// Delete the actual file with the name of the listName parameter
	///
	/// - Parameter listName: Name of the list file to delelte
	func deleteList(listName: String) {
		
		let fileManager = FileManager.default
		let fileNameWithExtension = listName + ".edenlist"
		let paths: [String] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentsDirectory:String = (paths.first)!
		
		if let destinationURL = NSURL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileNameWithExtension) {
			do {
				try fileManager.removeItem(at: destinationURL)
			} catch {
				print("Failed to remove the file \(destinationURL)")
			}
		}
	}
	
	/// When renaming a list, also rename the file
	///
	/// - Parameters:
	///   - oldFileName: Original file name
	///   - newFileName: New file name
	func renameList(from oldFileName: String, to newFileName: String) {
		let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentsDirectory: URL = URL(fileURLWithPath:paths.first!)
		
		let oldFilePath = documentsDirectory.appendingPathComponent("\(oldFileName).edenlist").path
		let newFilePath = documentsDirectory.appendingPathComponent("\(newFileName).edenlist").path
		
		if FileManager.default.fileExists(atPath: oldFilePath) {
			do {
				try FileManager.default.moveItem(atPath: oldFilePath, toPath: newFilePath)
			} catch {
				print("Could not move paths")
			}
		}
	}
	
	/// Check if a list with the given listName already exists
	///
	/// - Parameter listName: Name of the list being checked
	/// - Returns: True if the listName already exists, False if not
	func listExists(listName: String) -> Bool {
		let availableLists = self.lists()
		return availableLists.contains(listName)
	}
	
	
	/// Check if a file with the name of fileName exists
	///
	/// - Parameter fileName: The name of the file (does not contain the file extension)
	/// - Returns: Boolean result if the file exists or not
	func fileExists(fileName: String) -> Bool {

		let paths: [String] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentsDirectory:String = (paths.first)!
		
		let fileName = fileName + ".edenlist"
		let writePath = NSURL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileName)
		let filePath = (writePath?.path)!
		
		return FileManager.default.fileExists(atPath: filePath)
	}
}
