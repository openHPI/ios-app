//
//  TrackingEventVerb.swift
//  xikolo-ios
//
//  Created by Sebastian Brückner on 29.08.16.
//  Copyright © 2016 HPI. All rights reserved.
//

import Foundation

class TrackingEventVerb : NSObject, NSCoding {

    var type: String

    required init?(coder decoder: NSCoder) {
        guard let type = decoder.decodeObject(forKey: "type") as? String else {
            return nil
        }

        self.type = type
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.type, forKey: "type")
    }

//    required init(_ dict: [String : AnyObject]) {
//        if let type = dict["type"] as? String {
//            self.type = type
//        }
//    }
//
//    override init() {
//    }
//
//    func toDict() -> [String : AnyObject] {
//        var dict = [String: AnyObject]()
//        if let type = type {
//            dict["type"] = type as AnyObject?
//        }
//        return dict
//    }

}
