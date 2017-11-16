//
//  PeerAssessmentHelper.swift
//  xikolo-ios
//
//  Created by Bjarne Sievers on 18.09.16.
//  Copyright © 2016 HPI. All rights reserved.
//

import Foundation
import BrightFutures

struct PeerAssessmentHelper {

    static func syncPeerAssessment(_ peerAssessment: PeerAssessment) -> Future<PeerAssessment, XikoloError> {
        let fetchRequest = PeerAssessmentHelper.FetchRequest.peerAssessment(withId: peerAssessment.id)
        let query = SingleResourceQuery(resource: peerAssessment)
        return SyncEngine.syncResource(withFetchRequest: fetchRequest, withQuery: query)
    }
    
}
