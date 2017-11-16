//
//  PeerAssessment.swift
//  xikolo-ios
//
//  Created by Bjarne Sievers on 20.08.16.
//  Copyright © 2016 HPI. All rights reserved.
//

import CoreData
import Foundation
//import Spine

final class PeerAssessment : Content {

    @NSManaged var id: String
    @NSManaged var title: String?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PeerAssessment> {
        return NSFetchRequest<PeerAssessment>(entityName: "PeerAssessment");
    }

    override func iconName() -> String {
        return "peer_assessment"
    }

}

extension PeerAssessment : Pullable {

    static var type: String {
        return "peer-assessments"
    }

    func update(withObject object: ResourceData, including includes: [ResourceData]?, inContext context: NSManagedObjectContext) throws {
        let attributes = try object.value(for: "attributes") as JSON
        self.title = try attributes.value(for: "title")
    }

}

//@objcMembers
//class PeerAssessmentSpine : ContentSpine {
//
//    var title: String?
//
//    override class var cdType: BaseModel.Type {
//        return PeerAssessment.self
//    }
//
//    override class var resourceType: ResourceType {
//        return "peer-assessments"
//    }
//
//    override class var fields: [Field] {
//        return fieldsFromDictionary([
//            "title": Attribute()
//        ])
//    }
//
//}

