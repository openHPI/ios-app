//
//  QuizAnswer.swift
//  xikolo-ios
//
//  Created by Sebastian Brückner on 09.08.16.
//  Copyright © 2016 HPI. All rights reserved.
//

import Foundation
import Marshal

final class QuizOption : NSObject, NSCoding, Unmarshaling {

    var id: String
    var text: String?
    var position: Int32
    var correct: Bool
    var explanation: String?

//    required init(_ dict: [String : AnyObject]) {
//        id = dict["id"] as? String
//        text = dict["text"] as? String
//        position = dict["position"] as? NSNumber
//        correct = dict["correct"] as? Bool
//        explanation = dict["explanation"] as? String
//    }

    required init(object: ResourceData) throws {
        self.id = try object.value(for: "id")
        self.text = try object.value(for: "text")
        self.position = try object.value(for: "position")
        self.correct = try object.value(for: "correct")
        self.explanation = try object.value(for: "explanation")
    }

    required init(coder decoder: NSCoder) {
        self.id = decoder.decodeObject(forKey: "id") as! String // TODO: force cast
        self.text = decoder.decodeObject(forKey: "text") as? String
        self.position = decoder.decodeObject(forKey: "position") as! Int32  // TODO: force cast
        self.correct = decoder.decodeObject(forKey: "correct") as! Bool  // TODO: force cast
        self.explanation = decoder.decodeObject(forKey: "explanation") as? String
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.id, forKey: "id")
        coder.encode(self.text, forKey: "text")
        coder.encode(self.position, forKey: "position")
        coder.encode(self.correct, forKey: "correct")
        coder.encode(self.explanation, forKey: "explanation")
    }

}
