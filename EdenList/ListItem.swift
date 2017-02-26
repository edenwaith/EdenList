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
	
	convenience init(data: [String:AnyObject]) {
		self.init()
		
		itemTitle = data[kToDoKey] as? String ?? ""
		itemNotes = data[kNotesKey] as? String ?? ""
		itemChecked = data[kCheckBoxKey] as? Bool ?? false
	}
}
