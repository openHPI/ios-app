//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

public enum DateLabelHelper {

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter.localizedFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()

    public static func labelFor(startDate: Date?, endDate: Date?) -> String {
        if endDate?.inPast ?? false {
            return CommonLocalizedString("course-date-formatting.self-paced", comment: "Self-paced course")
        }

        if let startDate = startDate, startDate.inPast, endDate == nil {
            switch Brand.default.courseDateLabelStyle {
            case .normal:
                let format = CommonLocalizedString("course-date-formatting.started.since %@", comment: "course start at specfic date in the past")
                return String.localizedStringWithFormat(format, self.format(date: startDate))
            case .who:
                return CommonLocalizedString("course-date-formatting.self-paced", comment: "Self-paced course")
            }
        }

        if let startDate = startDate, startDate.inFuture, endDate == nil {
            switch Brand.default.courseDateLabelStyle {
            case .normal:
                let format = CommonLocalizedString("course-date-formatting.not-started.beginning %@", comment: "course start at specific date in the future")
                return String.localizedStringWithFormat(format, self.format(date: startDate))
            case .who:
                return CommonLocalizedString("course-date-formatting.not-started.coming soon", comment: "course start at unknown date")
            }
        }

        if let startDate = startDate, let endDate = endDate {
            return self.format(date: startDate) + " - " + format(date: endDate)
        }

        return CommonLocalizedString("course-date-formatting.not-started.coming soon", comment: "course start at unknown date")
    }

    private static func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }

}
