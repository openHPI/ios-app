//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import XCTest

class Screenshots: XCTestCase {

    override func setUp() {
        super.setUp()

        self.continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["-cleanStatusBar", "-cleanTabBar"]
        setupSnapshot(app)
        app.launch()
    }

    func testMakeScreenshots() {
        LoginHelper.logoutIfPossible()
        let app = XCUIApplication()

        // Course list
        Navigator.goToTabBarItem(.courses)
        sleep(5)
        snapshot("1-CourseList")

        LoginHelper.loginIfPossible()

        // Dashboard
        Navigator.goToTabBarItem(.dashboard)
        sleep(5)
        snapshot("2-Dashboard")

        // Course item list
        // tap on first element in course activity view
        // course cell must be accessibility element (.isAccessibilityElement = true)
        app.collectionViews.firstMatch.cells.firstMatch.tap()
        sleep(5)
        snapshot("3-Course-Items")

        // tap on first video item
        app.tables.cells.containing(XCUIElement.ElementType.button, identifier: nil).firstMatch.tap()
        sleep(4)
        snapshot("4-Video-Item")
    }

}
