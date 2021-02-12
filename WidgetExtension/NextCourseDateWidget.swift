//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import SwiftUI
import WidgetKit

struct NextCourseDateWidgetEntryView : View {
    var entry: NextCourseDateWidgetProvider.Entry

    var body: some View {
        if !entry.userIsLoggedIn {
            NotLoggedInView()
                .padding()
        } else if let courseDate = entry.courseDate {
            CourseDateView(courseDate: courseDate)
                .padding()
        } else {
            EmptyContentView()
                .padding()
        }
    }
}

struct NextCourseDateWidget: Widget {

    let kind = "next-course-date"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextCourseDateWidgetProvider()) { entry in
            NextCourseDateWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Course Date")
        .description("This is an example widget.")
        .supportedFamilies([.systemSmall])
    }

}
