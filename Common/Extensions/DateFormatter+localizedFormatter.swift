//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

extension DateFormatter {

    public static func localizedFormatter(dateStyle: DateFormatter.Style,
                                          timeStyle: DateFormatter.Style,
                                          locale: Locale = Brand.default.locale,
                                          calendar: Calendar = Calendar.autoupdatingCurrent,
                                          timeZone: TimeZone = TimeZone.autoupdatingCurrent) -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.calendar = calendar
        dateFormatter.timeZone = timeZone
        dateFormatter.dateStyle = dateStyle
        dateFormatter.timeStyle = timeStyle
        return dateFormatter
    }

}

extension DateIntervalFormatter {

    public static func localizedFormatter(dateStyle: DateIntervalFormatter.Style,
                                          timeStyle: DateIntervalFormatter.Style,
                                          locale: Locale = Brand.default.locale,
                                          calendar: Calendar = Calendar.autoupdatingCurrent,
                                          timeZone: TimeZone = TimeZone.autoupdatingCurrent) -> DateIntervalFormatter {
        let dateIntervalFormatter = DateIntervalFormatter()
        dateIntervalFormatter.locale = locale
        dateIntervalFormatter.calendar = calendar
        dateIntervalFormatter.timeZone = timeZone
        dateIntervalFormatter.dateStyle = dateStyle
        dateIntervalFormatter.timeStyle = timeStyle
        return dateIntervalFormatter
    }

}
