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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
