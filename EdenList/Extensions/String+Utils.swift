//
//  String+Utils.swift
//  EdenList
//
//  Created by Chad Armstrong on 3/29/17.
//  Copyright © 2017 Edenwaith. All rights reserved.
//

import Foundation

extension String {
	func localize() -> String {
		return NSLocalizedString(self, comment: self)
	}
}
