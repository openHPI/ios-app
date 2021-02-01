//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import WidgetKit

struct CourseDateOverviewWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> CourseDateOverviewWidgetEntry {
        let courseDateOverview = CourseDateOverviewViewModel(todayCount: 1, nextCount: 2, allCount: 4)
        return CourseDateOverviewWidgetEntry(courseDateOverview: courseDateOverview, userIsLoggedIn: UserProfileHelper.shared.isLoggedIn)
    }

    func getSnapshot(in context: Context, completion: @escaping (CourseDateOverviewWidgetEntry) -> ()) {
        CoreDataHelper.persistentContainer.performBackgroundTask { managedObjectContext in
            do {
                let todayCount = try managedObjectContext.count(for: CourseDateHelper.FetchRequest.courseDatesForNextDays(numberOfDays: 1))
                let nextCount = try managedObjectContext.count(for: CourseDateHelper.FetchRequest.courseDatesForNextDays(numberOfDays: 7))
                let allCount = try managedObjectContext.count(for: CourseDateHelper.FetchRequest.allCourseDates)
                let courseDateOverview = CourseDateOverviewViewModel(todayCount: todayCount, nextCount: nextCount, allCount: allCount)
                let entry = CourseDateOverviewWidgetEntry(courseDateOverview: courseDateOverview, userIsLoggedIn: UserProfileHelper.shared.isLoggedIn)
                completion(entry)
            } catch {
                let entry = CourseDateOverviewWidgetEntry(courseDateOverview: nil, userIsLoggedIn: UserProfileHelper.shared.isLoggedIn)
                completion(entry)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CourseDateOverviewWidgetEntry>) -> ()) {
        getSnapshot(in: context) { entry in
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }

}

struct CourseDateOverviewWidgetEntry: TimelineEntry {
    let date: Date = Date()
    let courseDateOverview: CourseDateOverviewViewModel?
    let userIsLoggedIn: Bool
}
