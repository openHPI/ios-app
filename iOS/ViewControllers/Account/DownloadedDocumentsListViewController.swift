//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import UIKit

class DownloadedDocumentsListViewController: UITableViewController {

    var courseID: String!

    private var dataSource: CoreDataTableViewDataSource<DownloadedDocumentsListViewController>!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let course = fetchCourse(withID: courseID) else { return }
        let request: NSFetchRequest<DocumentLocalization> = DocumentLocalizationHelper.FetchRequest.downloadedDocumentLocalizations(forCourse: course)

        let reuseIdentifier = "downloadItemCell"
        let resultsController = CoreDataHelper.createResultsController(request, sectionNameKeyPath: "document.title") // must be first sort descriptor
        self.dataSource = CoreDataTableViewDataSource(self.tableView,
                                                      fetchedResultsController: resultsController,
                                                      cellReuseIdentifier: reuseIdentifier,
                                                      delegate: self)

    }

    func configure(for courseID: String) {
        self.courseID = courseID
    }

    func fetchCourse(withID id: String) -> Course? {
        let request = CourseHelper.FetchRequest.course(withSlugOrId: id)
        return CoreDataHelper.viewContext.fetchSingle(request).value
    }

}

extension DownloadedDocumentsListViewController: CoreDataTableViewDataSourceDelegate {

    func configure(_ cell: UITableViewCell, for object: DocumentLocalization) {
        cell.textLabel?.text = object.languageCode
    }

    func canEditRow(at indexPath: IndexPath) -> Bool {
        return true
    }

    func commit(editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let documentLocalization = self.dataSource.object(at: indexPath)
            DocumentsPersistenceManager.shared.deleteDownload(for: documentLocalization)
        }
    }

}
