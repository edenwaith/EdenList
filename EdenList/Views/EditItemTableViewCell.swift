//
//  EditItemTableViewCell.swift
//  EdenList
//
//  Created by Chad Armstrong on 3/30/17.
//  Copyright © 2017 Edenwaith. All rights reserved.
//

import UIKit

class EditItemTableViewCell: UITableViewCell {

	@IBOutlet weak var itemLabel: UILabel!
	@IBOutlet weak var textField: UITextField!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
		if #available(iOS 13.0, *) {
			itemLabel.textColor = UIColor.link
		} else {
			// Fallback on earlier versions
			itemLabel.textColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
		}
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
