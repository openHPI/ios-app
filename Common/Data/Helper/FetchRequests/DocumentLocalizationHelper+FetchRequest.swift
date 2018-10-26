//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import CoreData

public enum DocumentLocalizationHelper {

    public enum FetchRequest {

        public static func publicDocumentLocalizations(forCourse course: Course) -> NSFetchRequest<DocumentLocalization> {
            let request: NSFetchRequest<DocumentLocalization> = DocumentLocalization.fetchRequest()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "%@ in document.courses", course),
                NSPredicate(format: "document.isPublic = %@", NSNumber(value: true)),
            ])
            let documentSortDescriptor = NSSortDescriptor(keyPath: \DocumentLocalization.document.title, ascending: true)
            let localizationSortDescriptor = NSSortDescriptor(keyPath: \DocumentLocalization.title, ascending: true)
            request.sortDescriptors = [documentSortDescriptor, localizationSortDescriptor]
            return request
        }

    }

}
