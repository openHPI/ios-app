//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import KeychainAccess

open class UserProfileHelper {

    static func login(_ email: String, password: String) -> Future<String, XikoloError> { // swiftlint:disable:this function_body_length
        let promise = Promise<String, XikoloError>()

        let parameters: String = [
            Routes.HeaderParameter.email: email,
            Routes.HeaderParameter.password: password,
        ].map { key, value in
            return "\(NetworkHelper.escape(key))=\(NetworkHelper.escape(value))"
        }.joined(separator: "&")

        var request = URLRequest(url: Routes.authenticate)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8, allowLossyConversion: false)

        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue(Routes.Header.userPlatformValue, forHTTPHeaderField: Routes.Header.userPlatformKey)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let err = error {
                promise.failure(.network(err))
                return
            }

            guard let urlResponse = response as? HTTPURLResponse else {
                promise.failure(.api(.invalidResponse))
                return
            }

            guard 200 ... 299 ~= urlResponse.statusCode else {
                promise.failure(.api(.responseError(statusCode: urlResponse.statusCode, headers: urlResponse.allHeaderFields)))
                return
            }

            guard let responseData = data else {
                promise.failure(.api(.noData))
                return
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
                    promise.failure(.api(.serializationError(.invalidDocumentStructure)))
                    return
                }

                guard let token = json["token"] as? String, let id = json["user_id"] as? String else {
                    promise.failure(.authenticationError)
                    return
                }

                UserProfileHelper.userToken = token
                UserProfileHelper.userId = id
                self.postLoginStateChange()
                return promise.success(token)
            } catch {
                promise.failure(.api(.serializationError(.jsonSerializationError(error))))
            }
        }

        NetworkIndicator.start()
        task.resume()
        return promise.future.onComplete { _ in
            NetworkIndicator.end()
        }
    }

    static func logout() {
        UserProfileHelper.clearKeychain()
        CoreDataHelper.clearCoreDataStorage().onComplete { _ in
            self.postLoginStateChange()
        }
    }

    static var isLoggedIn: Bool {
        return !self.userToken.isEmpty
    }

    static func postLoginStateChange() {
        let coursesFuture = CourseHelper.syncAllCourses().onSuccess { _ in
            AnnouncementHelper.syncAllAnnouncements()
        }

        if UserProfileHelper.isLoggedIn {
            coursesFuture.onSuccess { _ in
                CourseDateHelper.syncAllCourseDates()
            }
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NotificationKeys.loginStateChangedKey, object: nil)
        }
    }

}

extension UserProfileHelper {

    private enum KeychainKey: String {
        case userId = "de.xikolo.ios.user-id"
        case userToken = "de.xikolo.ios.user-token"
    }

    private static let keychain = Keychain(service: "de.xikolo.ios").accessibility(.afterFirstUnlock)

    static var userId: String? {
        get {
            return self.keychain[KeychainKey.userId.rawValue]
        }
        set {
            self.keychain[KeychainKey.userId.rawValue] = newValue
        }
    }

    static var userToken: String {
        get {
            return self.keychain[KeychainKey.userToken.rawValue] ?? ""
        }
        set {
            self.keychain[KeychainKey.userToken.rawValue] = newValue
        }
    }

    static func clearKeychain() {
        do {
            try self.keychain.removeAll()
        } catch {
            CrashlyticsHelper.shared.recordError(error)
            log.error("Failed to clear keychain - \(error)")
        }
    }

    static func migrateLegacyKeychain() {
        let defaults = UserDefaults.standard

        let legacyUserIdKey = "user"
        if let legacyUserId = defaults.string(forKey: legacyUserIdKey), !legacyUserId.isEmpty {
            self.userId = legacyUserId
            defaults.removeObject(forKey: legacyUserIdKey)
        }

        let legacyUserTokenKey = "user_token"
        if let legacyUserToken = defaults.string(forKey: legacyUserTokenKey), !legacyUserToken.isEmpty {
            self.userToken = legacyUserToken
            defaults.removeObject(forKey: legacyUserTokenKey)
        }

        defaults.synchronize()
    }
}
