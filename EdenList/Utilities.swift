//
//  Utilities.swift
//  EdenList
//
//  Created by Chad Armstrong on 3/31/25.
//

import UIKit

class Utilities {
    
    static func shareList(fileName: String, filePath: String, parentViewController: UIViewController, senderView: UIView? = nil, senderButton: UIBarButtonItem? = nil) {
        
        var records =  [ListItem]()
        let fileTitle = fileName
        let fileURL = NSURL(fileURLWithPath: filePath) // Can this be changed from NSURL to URL?
        
        var htmlContent = ""
        
        // Retrieve the print_template.html file and put into a string
        let templatePath = Bundle.main.path(forResource: "print_template", ofType: "html")
        
        (records, _) = Utilities.openFile(filePath: filePath)
        
        do {
            htmlContent = try String(contentsOfFile:templatePath!, encoding: String.Encoding.utf8)
            // Swap out the title with the name of the file to print
            htmlContent = htmlContent.replacingOccurrences(of: "__LIST_TITLE__", with: fileTitle)
            
            var itemsHTML = ""

            // Loop through the records and construct an HTML table for printing
            for item in records {
                let checkedOption: String = item.itemChecked ? "checked " : ""
                let itemTemplate = """
                    <tr>
                        <td><input type="checkbox" \(checkedOption)/></td>
                        <td>
                            <h4>\(item.itemTitle)</h4>
                            <h5>\(item.itemNotes)</h4>
                        </td>
                    </tr>
                """
                
                itemsHTML += itemTemplate
            }
 
            
            htmlContent = htmlContent.replacingOccurrences(of: "__LIST_ITEMS__", with: itemsHTML)
            
        } catch _ as NSError {
            
        }
        
        let printInfo = UIPrintInfo(dictionary:nil)
        printInfo.outputType = UIPrintInfo.OutputType.general
        printInfo.jobName = fileTitle
        printInfo.orientation = .portrait
        printInfo.duplex = .longEdge
        printInfo.outputType = .general
                
        let formatter = UIMarkupTextPrintFormatter(markupText: htmlContent)
        formatter.perPageContentInsets = UIEdgeInsets(top: 36, left: 36, bottom: 36, right: 36)
        
        let excludedTypes:[UIActivity.ActivityType] = [.postToFacebook, .postToTwitter, .postToVimeo, .postToWeibo, .postToFlickr, .addToReadingList, .assignToContact, .saveToCameraRoll]
        let shareVC = UIActivityViewController(activityItems: [fileTitle, fileURL, printInfo, formatter], applicationActivities: nil)

        shareVC.excludedActivityTypes = excludedTypes
        shareVC.setValue(fileTitle, forKey: "subject")
        
        // For iPad pop over
        if let popoverPresentationController = shareVC.popoverPresentationController {
            if let senderView = senderView {
                // From the HomeViewController
                popoverPresentationController.sourceView = senderView
                popoverPresentationController.sourceRect = senderView.bounds
            } else if let senderButton = senderButton {
                // From the ListItemsViewController
                popoverPresentationController.barButtonItem = senderButton
            }
        }
        
        // If displaying the share sheet is slow, use the dispatch queue
        DispatchQueue.main.async() {
            parentViewController.present(shareVC, animated: true, completion: nil)
        }
    }
    
    static func openFile(filePath: String) -> ([ListItem], VisibilityState) {
        
        var tempRecords = [ListItem]()
        var visibilityState: VisibilityState = .all
        
        if FileManager.default.fileExists(atPath: filePath) {
            if let fileContents = NSDictionary(contentsOfFile: filePath) {
                
                // File records
                if let fileRecords = fileContents[Constants.File.Records] as? [[String: Any]] {
                    for record in fileRecords {
                        let newRecord = ListItem(data: record)
                        tempRecords.append(newRecord)
                    }
                }
                
                // Visibility state
                if let visibility = fileContents[Constants.File.Visibility] as? Int {
                    if let tempVisibility = VisibilityState(rawValue: visibility) {
                        visibilityState = tempVisibility
                    }
                }
            }
        }
        
        return (tempRecords, visibilityState)
    }
}
