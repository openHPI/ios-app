//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import SwiftUI
import WidgetKit

struct ContinueLearningWidgetEntryView: View {
    var entry: ContinueLearningWidgetProvider.Entry

    var body: some View {
        if !entry.userIsLoggedIn {
            EmptyStateView.notLoggedIn
        } else if let course = entry.course {
            CourseView(course: course)
                .padding()
        } else {
            EmptyStateView.noCourses
        }
    }
}

struct ContinueLearningWidget: Widget {

    let kind = "continue-learning"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ContinueLearningWidgetProvider()) { entry in
            ContinueLearningWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("widget-metadata.continue-learning.title")
        .description("widget-metadata.continue-learning.description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }

}
