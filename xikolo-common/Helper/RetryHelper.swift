//
//  PromiseRetryHelper.swift
//  xikolo-ios
//
//  Created by Bjarne Sievers on 11.08.17.
//  Copyright © 2017 HPI. All rights reserved.
//

import Foundation
import BrightFutures

class RetryHelper {

    class func retry<T>(times: Int, block: @escaping () -> Future<T, XikoloError>) -> Future<T, XikoloError> {
        return self.retry(times: times, cooldown: 30, block: block)
    }

    class func retry<T>(times: Int, cooldown: TimeInterval, block: @escaping () -> Future<T, XikoloError>, cooldownRate: @escaping (TimeInterval) -> TimeInterval = { rate in return rate }) -> Future<T, XikoloError> {
        let future = block()

        if times-1 > 0 {
            return future.recoverWith { error in
                let nextCooldown = cooldownRate(cooldown)
                return self.after(interval: cooldown).flatMap { _ -> Future<T, XikoloError> in
                    let ablock = block
                    return self.retry(times: times-1, cooldown: nextCooldown, block: ablock, cooldownRate: cooldownRate)
                }
            }
        }
        return future
    }

    class func after(interval: TimeInterval) -> Future<Void, XikoloError > {
        return Future { complete in
            let when = DispatchTime.now() + interval
            DispatchQueue.global().asyncAfter(deadline: when) {
                complete(.success())
            }
        }
    }

}
