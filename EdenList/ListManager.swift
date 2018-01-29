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
	
	func recentList() -> String {
		let recentList = UserDefaults.standard.object(forKey: "Recent List") as? String ?? ""
		return recentList
	}
	
	func saveRecentList(_ recentList: String) {
		UserDefaults.standard.set(recentList, forKey: "Recent List")
		UserDefaults.standard.synchronize()
	}
}
