//
//  ListItem.swift
//  EdenList
//
//  Created by Chad Armstrong on 2/26/17.
//  Copyright © 2017 Edenwaith. All rights reserved.
//

import Foundation

let kToDoKey     = "ToDo"
let kNotesKey    = "Notes"
let kCheckBoxKey = "CheckBox"

class ListItem {
	
	var itemTitle: String = ""
	var itemNotes: String = ""
	var itemChecked: Bool = false
	
	convenience init(data: [String:Any]) {
		self.init()
		
		itemTitle = data[kToDoKey] as? String ?? ""
		itemNotes = data[kNotesKey] as? String ?? ""
		itemChecked = data[kCheckBoxKey] as? Bool ?? false
	}
	
	func copy(with zone: NSZone? = nil) -> ListItem {
		let data: [String: Any] = [kToDoKey: self.itemTitle,
		                           kNotesKey: self.itemNotes,
		                           kCheckBoxKey: self.itemChecked]
		let copy = ListItem(data: data)
		
		return copy
	}
	
	func description() -> String {
		return "\(itemTitle) \(itemNotes) \(itemChecked)"
	}
}
