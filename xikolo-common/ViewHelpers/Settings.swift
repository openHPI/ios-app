//
//  Settings.swift
//  xikolo-ios
//
//  Created by Sebastian Brückner on 23.06.16.
//  Copyright © 2016 HPI. All rights reserved.
//

import UIKit

class Settings {

    class func open() {
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(appSettings)
        }
    }

}
