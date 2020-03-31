//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Foundation
import Stockpile

public class HelpdeskTicket {

    public enum Topic {
        case technical
        case reactivation
        case courseSpecific(course: Course)

        var identifier: String {
            switch self {
            case .technical:
                return "technical"
            case .reactivation:
                return "reactivation"
            case .courseSpecific:
                return "course"
            }
        }
    }

    let title: String
    let mail: String
    let report: String
    let topic: Topic

    public init(title: String, mail: String, topic: Topic, report: String) {
        self.title = title
        self.mail = mail
        self.report = report
        self.topic = topic
    }

    private var currentTrackingData: String {
        return """
        platform: \(UIApplication.platform), \
        os version: \(UIApplication.osVersion), \
        device: \(UIApplication.device), \
        app name: \(UIApplication.appName), \
        app version: \(UIApplication.appVersion), \
        app build: \(UIApplication.appBuild)
        """
    }

    private var appLanguage: String {
        return Locale.supportedCurrent.identifier
    }

}

extension HelpdeskTicket: JSONAPIPushable {

    public var objectStateValue: Int16 {
        get {
            return ObjectState.new.rawValue
        }
        set {} // swiftlint:disable:this unused_setter_value
    }

    public static var type: String {
        return "tickets"
    }

    public func resourceAttributes() -> [String: Any] {
        return [
            "title": self.title,
            "mail": self.mail,
            "report": self.report,
            "topic": self.topic.identifier,
            "data": self.currentTrackingData,
            "language": self.appLanguage,
        ]
    }

    public func resourceRelationships() -> [String: AnyObject]? {
        if case let Topic.courseSpecific(course) = self.topic {
            return [ "course": course as AnyObject ]
        } else {
            return nil
        }
    }

}
