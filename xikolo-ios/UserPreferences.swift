//
//  UserPreferences.swift
//  xikolo-ios
//
//  Created by Jonas Müller on 08.07.15.
//  Copyright © 2015 HPI. All rights reserved.
//

import Foundation

class UserPreferences: NSObject {
    
    private let USER_ID = "id";
    private let USER_FIRST_NAME = "first_name";
    private let USER_LAST_NAME = "last_name";
    private let USER_EMAIL = "email";
    private let USER_ACCESS_TOKEN = "token";
    private let USER_VISUAL_URL = "visual_url";
    
    private let userDefaults = NSUserDefaults.standardUserDefaults();
    
    func getUser()->User {
        let user = User();
        
        user.id = userDefaults.stringForKey(USER_ID)!;
        user.firstName = userDefaults.stringForKey(USER_FIRST_NAME)!;
        user.lastName = userDefaults.stringForKey(USER_LAST_NAME)!;
        user.email = userDefaults.stringForKey(USER_EMAIL)!;
        user.visual = userDefaults.stringForKey(USER_VISUAL_URL)!;
        
//        // TODO
//        // Test data
//        user.id = "xyz";
//        user.firstName = "John";
//        user.lastName = "Doe";
//        user.email = "j.doe@example.com";
//        user.visual = "open.hpi.de"
//        // end
//        
//        saveUser(user);
        
        return user;
    }
    
    func saveUser(user: User) {
        userDefaults.setObject(user.id, forKey: USER_ID);
        userDefaults.setObject(user.firstName, forKey: USER_FIRST_NAME);
        userDefaults.setObject(user.lastName, forKey: USER_LAST_NAME);
        userDefaults.setObject(user.email, forKey: USER_EMAIL);
        userDefaults.setObject(user.visual, forKey: USER_VISUAL_URL);
    }
    
    func deleteUser(user: User) {
        userDefaults.removeObjectForKey(USER_ID);
        userDefaults.removeObjectForKey(USER_FIRST_NAME);
        userDefaults.removeObjectForKey(USER_LAST_NAME);
        userDefaults.removeObjectForKey(USER_ACCESS_TOKEN);
        userDefaults.removeObjectForKey(USER_VISUAL_URL);
    }
    
    func getAccessToken() {
        // TODO
    }
    
    func saveAccessToken() {
        // TODO
    }

}
