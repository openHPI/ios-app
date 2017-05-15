//
//  User.swift
//  xikolo-ios
//
//  Created by Jonas Müller on 08.07.15.
//  Copyright © 2015 HPI. All rights reserved.
//

import Alamofire
import BrightFutures
import Foundation

open class UserProfileHelper {

    enum Keys : String {
        case user = "user"
        case token = "user_token"
        case welcome = "show_welcome_screen"
    }

    static fileprivate let prefs = UserDefaults.standard

    static func login(_ email: String, password: String) -> Future<String, XikoloError> {
        let promise = Promise<String, XikoloError>()

        let url = Routes.AUTHENTICATE_API_URL
        Alamofire.request(url, method: .post, parameters:[
                Routes.HTTP_PARAM_EMAIL: email,
                Routes.HTTP_PARAM_PASSWORD: password,
        ], headers: NetworkHelper.getRequestHeaders()).responseJSON { response in
            // The API does not return valid JSON when returning a 401.
            // TODO: Remove once the API does that.
            if let response = response.response {
                if response.statusCode == 401 {
                    return promise.failure(XikoloError.authenticationError)
                }
            }

            if let json = response.result.value as? [String: Any] {
                if let token = json["token"] as? String {
                    UserProfileHelper.saveToken(token)
                    return promise.success(token)
                }
                return promise.failure(XikoloError.authenticationError)
            }
            if let error = response.result.error {
                return promise.failure(XikoloError.network(error))
            }
            return promise.failure(XikoloError.totallyUnknownError)
        }
        return promise.future
    }

    static func logout() {
        prefs.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        NotificationCenter.default.post(name: NotificationKeys.logoutSuccessfulKey, object: nil)
        prefs.synchronize()
        CoreDataHelper.clearCoreDataStorage()
    }

    static func getUser() -> Future<UserProfile, XikoloError> {
        if let user = loadUser() {
            return Future.init(value: user)
        } else {
            return UserProfileProvider.getMyProfile().onSuccess { user in
                UserProfileHelper.saveUser(user)
            }
        }
    }

    static fileprivate func loadUser() -> UserProfile? {
        if let data = prefs.object(forKey: Keys.user.rawValue) as? Data {
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? UserProfile
        }
        return nil
    }

    static func saveUser(_ user: UserProfile) {
        prefs.set(NSKeyedArchiver.archivedData(withRootObject: user), forKey: Keys.user.rawValue)
        prefs.synchronize()
    }

    static func isLoggedIn() -> Bool {
        return !getToken().isEmpty
    }

    static func getToken() -> String {
        return get(.token) ?? ""
    }

    static func save(_ key: Keys, withValue value: String) {
        prefs.set(value, forKey: key.rawValue)
        prefs.synchronize()
    }

    static func get(_ key: Keys) -> String? {
        return prefs.string(forKey: key.rawValue)
    }

    static func saveToken(_ token: String) {
        save(.token, withValue: token)
        NotificationCenter.default.post(name: NotificationKeys.loginSuccessfulKey, object: nil)
        prefs.synchronize()
        refreshUserDependentData()
    }

    static func refreshUserDependentData() {
        CourseHelper.refreshCourses()
        CourseDateHelper.syncCourseDates()
        NewsArticleHelper.syncNewsArticles()
    }

}
