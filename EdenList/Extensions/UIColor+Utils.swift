//
//  UIColor+Utils.swift
//  EdenList
//
//  Created by Chad Armstrong on 4/18/20.
//  Copyright © 2020 Edenwaith. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
	
	/// Set a custom background color for the app to fix some visual
	/// glitches during view controller transitions
	class var customBackgroundColor: UIColor {
		if #available(iOS 13.0, *) {
			return .systemBackground
		} else {
			// Fallback on earlier versions
			return .white
		}
	}
	
	class var customGrey:UIColor {
		if #available(iOS 13.0, *) {
			return UIColor.systemGray
		} else {
			// Fallback on earlier versions
			return UIColor.darkGray
		}
	}
	
	class var customLinkColor:UIColor  {
		if #available(iOS 13.0, *) {
			return UIColor.link
		} else {
			// Fallback on earlier versions
			return UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
		}
	}
}
