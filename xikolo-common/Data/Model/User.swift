//
//  User.swift
//  xikolo-ios
//
//  Created by Bjarne Sievers on 22.03.17.
//  Copyright © 2017 HPI. All rights reserved.
//

import Foundation
import CoreData
import BrightFutures

final class User: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var name: String?
    @NSManaged var avatarURL: URL?
    @NSManaged var profile: UserProfile?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User");
    }

}

extension User : Pullable {

    static var type: String {
        return "users"
    }

    func update(withObject object: ResourceData, including includes: [ResourceData]?, inContext context: NSManagedObjectContext) throws {
        let attributes = try object.value(for: "attributes") as JSON
        self.name = try attributes.value(for: "name")
        self.avatarURL = try attributes.value(for: "avatar_url")

        let relationships = try object.value(for: "relationships") as JSON
        try self.updateRelationship(forKeyPath: \User.profile, forKey: "profile", fromObject: relationships, including: includes, inContext: context)
    }

}
