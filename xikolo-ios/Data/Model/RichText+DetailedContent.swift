//
//  RichText+DetailedContent.swift
//  xikolo-ios
//
//  Created by Max Bothe on 20/07/17.
//  Copyright © 2017 HPI. All rights reserved.
//

import BrightFutures
import Foundation

extension RichText: DetailedContent {

    var detailedInformation: String? {

        let words = self.text?.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        guard let wordcount = words?.count else {
            return nil
        }
        var calendar = Calendar.current
        calendar.locale = Locale.current
        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.minute]
        formatter.zeroFormattingBehavior = [.pad]
        guard let durationText = formatter.string(from: ceil(Double(wordcount)/200)*60) else {
            return nil
        }
        return "~\(durationText)"
    }

    static func preloadContentFor(course: Course) -> Future<[CourseItem], XikoloError> {
        return CourseItemHelper.syncRichTextsFor(course: course)
    }

}
