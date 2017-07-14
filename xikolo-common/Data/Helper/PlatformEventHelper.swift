//
//  PlatformEventHelper.swift
//  xikolo-ios
//
//  Created by Bjarne Sievers on 07.09.16.
//  Copyright © 2016 HPI. All rights reserved.
//

import BrightFutures
import CoreData
import Result

class PlatformEventHelper {

    static func getRequest() -> NSFetchRequest<PlatformEvent> {
        let request: NSFetchRequest<PlatformEvent> = PlatformEvent.fetchRequest()
        let dateSort = NSSortDescriptor(key: "created_at", ascending: false)
        request.sortDescriptors = [dateSort]
        return request
    }

    static func syncPlatformEvents() -> Future<[PlatformEvent], XikoloError> {
        return PlatformEventProvider.getPlatformEvents().flatMap { spinePlatformEvents -> Future<[PlatformEvent], XikoloError> in
            let request = getRequest()
            return SpineModelHelper.syncObjectsFuture(request, spineObjects: spinePlatformEvents, inject: nil, save: true)
        }
    }
    
}
