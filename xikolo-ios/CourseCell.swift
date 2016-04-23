//
//  CourseCell.swift
//  xikolo-ios
//
//  Created by Jonas Müller on 16.07.15.
//  Copyright © 2015 HPI. All rights reserved.
//

import UIKit

class CourseCell: UICollectionViewCell {
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var buttonEnter: UIButton!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var teacherLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    func configure(course: Course) {
        layer.cornerRadius = 3

        ImageProvider.loadImage(course.image_url!, imageView: backgroundImage)

        nameLabel.text = course.name
        teacherLabel.text = course.teachers
        dateLabel.text = course.language
    }

}
