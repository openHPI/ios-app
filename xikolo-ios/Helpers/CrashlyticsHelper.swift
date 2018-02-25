//
//  CrashlyticsHelper.swift
//  xikolo-ios
//
//  Created by Max Bothe on 16.02.18.
//  Copyright © 2018 HPI. All rights reserved.
//

import Crashlytics

struct CrashlyticsHelper {

    static var shared: Crashlytics {
        return Crashlytics.sharedInstance()
    }

}

extension Crashlytics {

    func recordAPIError(_ error: XikoloError) {
        guard case .api(_) = error else { return }
        if case let .api(.responseError(statusCode: statusCode, headers: _)) = error,
            !(200 ... 299 ~= statusCode || statusCode == 406 || statusCode == 503) { return }
        CrashlyticsHelper.shared.recordError(error)
    }
}
