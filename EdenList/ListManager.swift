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
	
	func lists() -> [AnyObject] {
		if let availableLists = UserDefaults.standard.array(forKey: "Lists") as? [AnyObject] {
			return availableLists
		} else {
			return []
		}
	}
}
