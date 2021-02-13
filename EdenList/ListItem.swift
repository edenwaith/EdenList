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
let kIndexKey	 = "Index"

class ListItem: NSObject, NSCoding {

	var itemTitle: String = ""
	var itemNotes: String = ""
	var itemChecked: Bool = false
	var itemIndex: Int = -1	// Original index in the records array, used as a unique ID when referencing that item
	
	convenience override init() {
		let emptyData = [String:Any]()
		self.init(data: emptyData)
	}
	
	init(data: [String:Any]) {	
		itemTitle = data[kToDoKey] as? String ?? ""
		itemNotes = data[kNotesKey] as? String ?? ""
		itemChecked = data[kCheckBoxKey] as? Bool ?? false
		itemIndex = data[kIndexKey] as? Int ?? -1
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(itemTitle, forKey: kToDoKey)
		
	}
	
	required init?(coder aDecoder: NSCoder) {
		itemTitle = aDecoder.decodeObject(forKey: kToDoKey) as? String ?? ""
	}
	
	func copy(with zone: NSZone? = nil) -> ListItem {
		let data: [String: Any] = [kToDoKey: self.itemTitle,
		                           kNotesKey: self.itemNotes,
		                           kCheckBoxKey: self.itemChecked,
								   kIndexKey: self.itemIndex]
		let copy = ListItem(data: data)
		
		return copy
	}
	
	func listItemAsDictionary() -> NSDictionary {
		return [kToDoKey: itemTitle, kNotesKey: itemNotes, kIndexKey: itemIndex, kCheckBoxKey: itemChecked]
	}
	
	// Encoding and decoding custom class https://stackoverflow.com/questions/27197658/writing-swift-dictionary-to-file
	
//	@objc override func description() -> String {
//		return "\(itemTitle) \(itemNotes) \(itemChecked)"
//	}
}
