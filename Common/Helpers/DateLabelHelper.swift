//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

public struct DateLabelHelper {

    fileprivate static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter.localizedFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()

    public static func labelFor(startDate: Date?, endDate: Date?) -> String {
        if endDate?.inPast ?? false {
            return NSLocalizedString("course-date-formatting.self-paced",
                                     tableName: "Common",
                                     bundle: Bundle(for: Course.self),
                                     comment: "Self-paced course")
        }

        if let startDate = startDate, startDate.inPast, endDate == nil {
            switch Brand.default.courseDateLabelStyle {
            case .normal:
                let format = NSLocalizedString("course-date-formatting.started.since %@",
                                               tableName: "Common",
                                               bundle: Bundle(for: Course.self),
                                               comment: "course start at specfic date in the past")
                return String.localizedStringWithFormat(format, self.format(date: startDate))
            case .who:
                return NSLocalizedString("course-date-formatting.self-paced",
                                         tableName: "Common",
                                         bundle: Bundle(for: Course.self),
                                         comment: "Self-paced course")
            }
        }

        if let startDate = startDate, startDate.inFuture, endDate == nil {
            switch Brand.default.courseDateLabelStyle {
            case .normal:
                let format = NSLocalizedString("course-date-formatting.not-started.beginning %@",
                                               tableName: "Common",
                                               bundle: Bundle(for: Course.self),
                                               comment: "course start at specific date in the future")
                return String.localizedStringWithFormat(format, self.format(date: startDate))
            case .who:
                return NSLocalizedString("course-date-formatting.not-started.coming soon",
                                         tableName: "Common",
                                         bundle: Bundle(for: Course.self),
                                         comment: "course start at unknown date")
            }
        }

        if let startDate = startDate, let endDate = endDate {
            return self.format(date: startDate) + " - " + format(date: endDate)
        }

        return NSLocalizedString("course-date-formatting.not-started.coming soon",
                                 tableName: "Common",
                                 bundle: Bundle(for: Course.self),
                                 comment: "course start at unknown date")
    }

    private static func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }

}
