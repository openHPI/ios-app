//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import UIKit

enum CourseSearchFilter: CaseIterable {
    case language

    var isAvailable: Bool {
        return true
    }

    var title: String {
        switch self {
        case .language:
            return NSLocalizedString("course-list.search.filter.title.language", comment: "Title for language filter")
        }
    }

    var options: [String] {
        switch self {
        case .language:
            let fetchRequest = CourseHelper.FetchRequest.distinctLanguages
            let dicts = try? CoreDataHelper.viewContext.fetch(fetchRequest)
            let values = dicts?.flatMap { $0.allValues }.compactMap { $0 as? String }
            return values ?? []
        }
    }

    func displayName(forOption option: String) -> String? {
        switch self {
        case .language:
            return Course.localize(language: option)
        }
    }

    func predicate(forSelectedOptions selectedOptions: Set<String>) -> NSPredicate {
        switch self {
        case .language:
            let languagePredicates = selectedOptions.map { NSPredicate(format: "language == %@", $0) }
            return NSCompoundPredicate(orPredicateWithSubpredicates: languagePredicates)
        }
    }

    static var availableCases: [CourseSearchFilter] {
        return CourseSearchFilter.allCases.filter { $0.isAvailable }
    }
}
