//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

extension UIApplication {

    #if os(tvOS)
    static let platform = "tvOS"
    #else
    static let platform = "iOS"
    #endif

    static let osVersion: String = {
        let version = ProcessInfo().operatingSystemVersion
        return String(format: "%d.%d.%d", version.majorVersion, version.minorVersion, version.patchVersion)
    }()

    static let device: String = {
        var sysinfo = utsname()
        uname(&sysinfo)
        var name = withUnsafeMutablePointer(to: &sysinfo.machine) { ptr in
            String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }

        if ["i386", "x86_64"].contains(name) {
            name = "Simulator"
        }

        return name
    }()

}
