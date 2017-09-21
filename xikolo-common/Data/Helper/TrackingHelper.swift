//
//  TrackingHelper.swift
//  xikolo-ios
//
//  Created by Sebastian Brückner on 31.08.16.
//  Copyright © 2016 HPI. All rights reserved.
//

import BrightFutures
import UIKit

class TrackingHelper {

    fileprivate class func defaultContext() -> [String: String] {
        let screenSize = UIScreen.main.bounds.size
        let windowSize = (UIApplication.shared.delegate as? AppDelegate)?.window?.frame.size

        return [
            "platform": UIApplication.platform,
            "platform_version": UIApplication.osVersion,
            "runtime": UIApplication.platform,
            "runtime_version": UIApplication.osVersion,
            "device": UIApplication.device,
            "build_version_name": UIApplication.appVersion(),
            "build_version": UIApplication.appBuild(),
            "screen_width": String(Int(screenSize.width)),
            "screen_height": String(Int(screenSize.height)),
            "window_width": String(Int(windowSize?.width ?? 0)),
            "window_height": String(Int(windowSize?.height ?? 0)),
            "client_id": UIDevice.current.identifierForVendor?.uuidString ?? "",
            "free_space": String(describing: self.systemFreeSize),
            "total_space": String(describing: self.systemSize),
        ]
    }

    fileprivate class func createEvent(_ verb: String, resource: BaseModel?, context: [String: String?] = [:]) -> Future<TrackingEvent, XikoloError> {

        let trackingVerb = TrackingEventVerb()
        trackingVerb.type = verb

        var trackingContext = defaultContext()

        for (k, v) in context {
            if let v = v {
                trackingContext.updateValue(v, forKey: k)
            }
        }

        let trackingEvent = TrackingEvent()
        let trackingUser = TrackingEventUser()
        trackingUser.uuid = UserProfileHelper.getUserId()
        trackingEvent.user = trackingUser
        trackingEvent.verb = trackingVerb
        if let resource = resource {
            trackingEvent.resource = TrackingEventResource(resource: resource)
        } else {
            //this is a fallback required by the tracking API where ressource cant be empty
            trackingEvent.resource = TrackingEventResource(type: "None")
        }
        trackingEvent.timestamp = Date()
        trackingEvent.context = trackingContext as [String : AnyObject]?
        return Future.init(value: trackingEvent)
    }

    @discardableResult class func sendEvent(_ verb: String, resource: BaseModel?, context: [String: String?] = [:]) -> Future<Void, XikoloError> {
        return createEvent(verb, resource: resource, context: context).flatMap { event -> Future<Void, XikoloError> in
            SpineHelper.save(event).asVoid()
        }
    }

}

extension TrackingHelper {

    fileprivate static var systemFreeSize: UInt64 {
        return self.deviceData(for: .systemFreeSize) ?? 0
    }

    fileprivate static var systemSize: UInt64 {
        return self.deviceData(for: .systemSize) ?? 0
    }

    private static func deviceData(for key: FileAttributeKey) -> UInt64? {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last else {
            return nil
        }

        guard let deviceData = try? FileManager.default.attributesOfFileSystem(forPath: path) else {
            return nil
        }

        guard let value = deviceData[key] as? NSNumber else {
            return nil
        }

        return value.uint64Value
    }

}
