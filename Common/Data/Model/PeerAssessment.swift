//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import SyncEngine

final class PeerAssessment: Content {

    @NSManaged var id: String
    @NSManaged var title: String?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PeerAssessment> {
        return NSFetchRequest<PeerAssessment>(entityName: "PeerAssessment")
    }

}

extension PeerAssessment: JSONAPIPullable {

    public static var type: String {
        return "peer-assessments"
    }

    public func update(from object: ResourceData, with context: SynchronizationContext) throws {
        let attributes = try object.value(for: "attributes") as JSON
        self.title = try attributes.value(for: "title")
    }

}
