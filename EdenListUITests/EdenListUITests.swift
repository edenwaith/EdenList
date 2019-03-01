//
//  EdenListUITests.swift
//  EdenListUITests
//
//  Created by Chad Armstrong on 2/14/17.
//  Copyright © 2017 Edenwaith. All rights reserved.
//

import XCTest

class EdenListUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
		
				/*
		let app = XCUIApplication()
		let edenlistButton = app.navigationBars["Space Quest Games"].buttons["EdenList"]
		edenlistButton.tap()
		
		let edenlistNavigationBar = app.navigationBars["EdenList"]
		let addButton = edenlistNavigationBar.buttons["Add"]
		addButton.tap()
		
		let addNewListNavigationBar = app.navigationBars["Add New List"]
		addNewListNavigationBar.buttons["Cancel"].tap()
		
		let editButton = edenlistNavigationBar.buttons["Edit"]
		editButton.tap()
		
		let tablesQuery = app.tables
		let deleteSpaceQuestGamesButton = tablesQuery/*@START_MENU_TOKEN@*/.buttons["Delete Space Quest Games"]/*[[".cells.buttons[\"Delete Space Quest Games\"]",".buttons[\"Delete Space Quest Games\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		deleteSpaceQuestGamesButton.tap()
		
		let deleteButton = tablesQuery.buttons["Delete"]
		deleteButton.tap()
		addButton.tap()
		
		let saveButton = addNewListNavigationBar.buttons["Save"]
		saveButton.tap()
		
		let doneButton = edenlistNavigationBar.buttons["Done"]
		doneButton.tap()
		editButton.tap()
		deleteSpaceQuestGamesButton.tap()
		deleteButton.tap()
		doneButton.tap()
		addButton.tap()
		saveButton.tap()
		tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Space Quest Games"]/*[[".cells.staticTexts[\"Space Quest Games\"]",".staticTexts[\"Space Quest Games\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
		
		let addButton2 = app.toolbars["Toolbar"].buttons["Add"]
		addButton2.tap()
		
		let saveButton2 = app.navigationBars["New Item"].buttons["Save"]
		saveButton2.tap()
		addButton2.tap()
		saveButton2.tap()
		addButton2.tap()
		saveButton2.tap()
		edenlistButton.tap()
		*/
		
		let app = XCUIApplication()
		
	
		app.navigationBars["EdenList"].buttons["Add"].tap()
		app.navigationBars["Add New List"].buttons["Save"].tap()
		app.tables/*@START_MENU_TOKEN@*/.staticTexts["King’s Quest Games"]/*[[".cells.staticTexts[\"King’s Quest Games\"]",".staticTexts[\"King’s Quest Games\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
		app.navigationBars["King’s Quest Games"].buttons["EdenList"].tap()
		
		
		
		
		//		app.navigationBars["EdenList"].buttons["Add"].tap()
//		app.navigationBars["Add New List"].buttons["Save"].tap()
//		app.tables/*@START_MENU_TOKEN@*/.staticTexts["King’s Quest Games"]/*[[".cells.staticTexts[\"King’s Quest Games\"]",".staticTexts[\"King’s Quest Games\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//		app.navigationBars["King’s Quest Games"].buttons["EdenList"].tap()
		
		
		
//		app.toolbars.buttons["Add"].tap()
//		app.navigationBars["New Item"].buttons["Cancel"].tap()
		        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
	
	func testLoadDummyData() {
		
		let app = XCUIApplication()
		app.navigationBars["EdenList"].buttons["Add"].tap()
		app.navigationBars["Add New List"].buttons["Save"].tap()
		app.tables/*@START_MENU_TOKEN@*/.staticTexts["King’s Quest Games"]/*[[".cells.staticTexts[\"King’s Quest Games\"]",".staticTexts[\"King’s Quest Games\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
		
		let addButton = app.toolbars["Toolbar"].buttons["Add"]
		addButton.tap()
		
		let saveButton = app.navigationBars["New Item"].buttons["Save"]
		saveButton.tap()
		addButton.tap()
		saveButton.tap()
		addButton.tap()
		saveButton.tap()
	}
    
}
