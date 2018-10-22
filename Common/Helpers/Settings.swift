//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

enum Settings {

    static func open() {
        guard let appSettings = URL(string: UIApplicationOpenSettingsURLString) else { return }
        guard UIApplication.shared.canOpenURL(appSettings) else { return }
        UIApplication.shared.open(appSettings)
    }

}
