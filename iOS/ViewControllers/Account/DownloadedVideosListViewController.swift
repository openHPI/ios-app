//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import UIKit

class DownloadedVideosListViewController: UITableViewController {

    var courseID: String!

    var resultsController: NSFetchedResultsController<Video>!

    override func viewDidLoad() {
        super.viewDidLoad()
        let request: NSFetchRequest<Video> = VideoHelper.FetchRequest.hasDownloadedVideo(inCourse: courseID)
        resultsController = CoreDataHelper.createResultsController(request, sectionNameKeyPath: "item.section.title")
        do {
            try resultsController.performFetch()
        } catch {
            log.error()
        }

    }

    func configure(for courseID: String) {
        self.courseID = courseID
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return resultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "downloadItemCell", for: indexPath)
        let video = resultsController.object(at: indexPath)
        cell.textLabel?.text = video.item?.title ?? video.summary ?? ""
        // cell.detailTextLabel?.text = self.downloadType == .video ? video.singleStream.
        // TODO: maybe set size
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let video = resultsController.object(at: indexPath)
            StreamPersistenceManager.shared.deleteDownload(for: video)
        }
    }

}
