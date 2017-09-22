//
//  Int+DispatchTime.swift
//  xikolo-ios
//
//  Created by Max Bothe on 22.09.17.
//  Copyright © 2017 HPI. All rights reserved.
//

import Foundation

public extension Int {

    public var seconds: DispatchTimeInterval {
        return DispatchTimeInterval.seconds(self)
    }

    public var second: DispatchTimeInterval {
        return seconds
    }

    public var milliseconds: DispatchTimeInterval {
        return DispatchTimeInterval.milliseconds(self)
    }

    public var millisecond: DispatchTimeInterval {
        return milliseconds
    }

}

public extension DispatchTimeInterval {
    public var fromNow: DispatchTime {
        return DispatchTime.now() + self
    }
}
