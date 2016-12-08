//
//  Course.swift
//  xikolo-ios
//
//  Created by Sebastian Brückner on 22.04.16.
//  Copyright © 2016 HPI. All rights reserved.
//

import BrightFutures
import CoreData
import Foundation
import Spine

class Course : BaseModel {

    var hidden: Bool? {
        get {
            return hidden_int?.boolValue
        }
        set(new_is_hidden) {
            hidden_int = new_is_hidden
        }
    }

    var open: Bool? {
        get {
            return open_int?.boolValue
        }
        set(new_is_open) {
            open_int = new_is_open
        }
    }

    var external: Bool? {
        get {
            return external_int?.boolValue
        }
        set(new_is_external) {
            external_int = new_is_external
        }
    }

    var is_enrolled_section: String {
        get {
            if enrollment != nil {
                return NSLocalizedString("My Courses", comment: "My Courses")
            } else {
                return NSLocalizedString("All Courses", comment: "All Courses")
            }
        }
    }

    var language_translated: String? {
        if let language = language {
            let locale = NSLocale.currentLocale()
            return locale.displayNameForKey(NSLocaleIdentifier, value: language)
        }
        return nil
    }

    func loadImage() -> Future<UIImage, XikoloError> {
        if let image = image {
            return Future.init(value: image)
        }
        if let imageUrl = image_url {
            return ImageProvider.loadImage(imageUrl).onSuccess { image in
                self.image = image
                CoreDataHelper.saveContext()
            }
        } else {
            return Future.init(error: XikoloError.ModelIncomplete)
        }
    }

}

class CourseSpine : BaseModelSpine {

    var title: String?
    var slug: String?
    var abstract: String?
    var course_description: String?
    var image_url: NSURL?
    var teachers: String?
    var language: String?
    var start_at: NSDate?
    var end_at: NSDate?
    var status: String?
    var hidden_int: NSNumber?
    var open_int: NSNumber?
    var external_int: NSNumber?

    var enrollment: CourseEnrollmentSpine?
    var channel: ChannelSpine?

    override class var cdType: BaseModel.Type {
        return Course.self
    }

    override class var resourceType: ResourceType {
        return "courses"
    }

    override class var fields: [Field] {
        return fieldsFromDictionary([
            "title": Attribute(),
            "slug": Attribute(),
            "abstract": Attribute(),
            "course_description": Attribute().serializeAs("description"),
            "image_url": URLAttribute(baseURL: NSURL(string: Brand.BaseURL)!),
            "teachers": Attribute(),
            "language": Attribute(),
            "start_at": DateAttribute(),
            "end_at": DateAttribute(),
            "status": Attribute(),
            "hidden_int": Attribute().serializeAs("hidden"),
            "open_int": Attribute().serializeAs("open"),
            "external_int": Attribute().serializeAs("external"),
            "enrollment": ToOneRelationship(CourseEnrollmentSpine).serializeAs("user_enrollment"),
            "channel": ToOneRelationship(ChannelSpine),
        ])
    }

}
