//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

public protocol ErrorReporter {

    func report(_ error: Error)

}

public class ErrorManager {

    private var reporters: [ErrorReporter] = []

    public static let shared = ErrorManager()

    public func register(reporter: ErrorReporter) {
        self.reporters.append(reporter)
    }

    public func report(_ error: Error) {
        self.reporters.forEach { $0.report(error) }
    }

    func reportAPIError(_ error: XikoloError) {
        guard case .synchronization(.api(_)) = error else { return }
        if case let .synchronization(.api(.response(statusCode: statusCode, headers: _))) = error,
            !(200 ... 299 ~= statusCode || statusCode == 406 || statusCode == 503) { return }
        self.report(error)
    }

}
