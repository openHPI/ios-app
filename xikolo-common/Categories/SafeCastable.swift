//
//  SafeCastable.swift
//  xikolo-ios
//
//  Created by Max Bothe on 05.01.18.
//  Copyright © 2018 HPI. All rights reserved.
//

import UIKit

protocol SafeCastable {

    func require<T>(toHaveType type: T.Type,
                    hint hintExpression: @autoclosure () -> String?,
                    file: StaticString,
                    line: UInt) -> T

}

extension SafeCastable {

    func require<T>(toHaveType type: T.Type,
                    hint hintExpression: @autoclosure () -> String? = nil,
                    file: StaticString = #file,
                    line: UInt = #line) -> T {
        guard let unwrapped = self as? T else {
            var message = "Required value was not of type \(T.self) in \(file), at line \(line)"

            if let hint = hintExpression() {
                message.append(". Debugging hint: \(hint)")
            }

            log.severe(message)

            let exception = NSException(
                name: .invalidArgumentException,
                reason: message,
                userInfo: nil
            )
            exception.raise()

            fatalError(message)
        }

        return unwrapped
    }

}

extension UIView : SafeCastable {}
extension UIViewController : SafeCastable {}
