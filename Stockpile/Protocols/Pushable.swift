//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import CoreData

public protocol Pushable: ResourceTypeRepresentable, IncludedPushable, Validatable, AnyObject {

    static func resourceData(attributes: [String: Any], relationships: [String: AnyObject]?) -> Result<Data, SyncError>

    var objectStateValue: ObjectState.RawValue { get set }

    func resourceData() -> Result<Data, SyncError>
    func resourceRelationships() -> [String: AnyObject]?
    func markAsUnchanged()

}

public extension Pushable {

    func markAsUnchanged() { }

    func resourceRelationships() -> [String: AnyObject]? {
        return nil
    }

}

extension Pushable where Self: NSManagedObject {

    public var objectState: ObjectState {
        get {
            return ObjectState(rawValue: self.objectStateValue) ?? .unchanged
        }
        set {
            self.objectStateValue = newValue.rawValue
        }
    }

}
