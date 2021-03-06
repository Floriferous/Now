//
//  User.swift
//  Now
//
//  Created by Pierre Starkov on 12/07/16.
//  Copyright © 2016 Now. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth

class User {
    fileprivate(set) var id: String?
    fileprivate(set) var username: String?
    fileprivate(set) var email: String?
    fileprivate(set) var imageURL: URL?
    fileprivate(set) var followerCount: Int?
    fileprivate(set) var followingCount: Int?
    fileprivate(set) var upCount: Int?
    fileprivate(set) var postCount: Int?
    fileprivate(set) var creationTime: Date?
    
    
    init() {}
    
    // Load data from snapshot into User
    convenience init(snapshot: FIRDataSnapshot) {
        self.init()
        
        
        
        id = String(snapshot.key)
        username = (snapshot.value as? NSDictionary)![UserFields.username] as? String
        email = (snapshot.value as? NSDictionary)![UserFields.email] as? String
        followerCount = Int(snapshot.childSnapshot(forPath: UserFields.followers).childrenCount)
        followingCount = Int(snapshot.childSnapshot(forPath: UserFields.following).childrenCount)
        upCount = Int(snapshot.childSnapshot(forPath: UserFields.ups).childrenCount)
        postCount = Int(snapshot.childSnapshot(forPath: UserFields.posts).childrenCount)
        
        if let time = (snapshot.value as? NSDictionary)![UserFields.date] as? Double {
            creationTime = Date(timeIntervalSince1970: time/1000)
        }
    }
    
    //    convenience init(user: FIRUser?, newUsername: String) {
    //        self.init()
    //        if user != nil {
    //            id = user!.uid
    //            email = user!.email
    //            username = newUsername
    //        }
    //    }
    
    // Create User array
    class func parseFromSnapshot(_ snapshot: FIRDataSnapshot) -> [User] {
        var users = [User]()
        for child in snapshot.children {
            let user = User.init(snapshot: child as! FIRDataSnapshot)
            users.insert(user, at: 0)
        }
        return users
    }
    
//    class func NSDefaultsToUser() -> User {
//        let defaults = NSUserDefaults.standardUserDefaults()
//        let user = User()
//        
//        user.id = defaults.objectForKey(UserFields.id) as? String
//        user.username = defaults.objectForKey(UserFields.username) as? String
//        user.email = defaults.objectForKey(UserFields.email) as? String
//        user.imageURL = defaults.objectForKey(UserFields.imageURL) as? NSURL
//        user.followerCount = defaults.objectForKey(UserFields.followerCount) as? Int
//        user.followingCount = defaults.objectForKey(UserFields.followingCount) as? Int
//        user.postCount = defaults.objectForKey(UserFields.postCount) as? Int
//        user.creationTime = defaults.objectForKey(UserFields.date) as? NSDate
//        
//        return user
//    }
//    
//    func UserToNSDefaults() {
//        
//        let defaults = NSUserDefaults.standardUserDefaults()
//        
//        if id != nil {
//            defaults.setObject(id!, forKey: UserFields.id)
//        }
//        if username != nil {
//            defaults.setObject(username!, forKey: UserFields.username)
//        }
//        if email != nil {
//            defaults.setObject(email!, forKey: UserFields.email)
//        }
//        if followingCount != nil {
//            defaults.setObject(followerCount!, forKey: UserFields.followerCount)
//        }
//        if followingCount != nil {
//            defaults.setObject(followingCount!, forKey: UserFields.followingCount)
//        }
//        if upCount != nil {
//            defaults.setObject(upCount!, forKey: UserFields.upCount)
//        }
//        if postCount != nil {
//            defaults.setObject(postCount!, forKey: UserFields.postCount)
//        }
//        if creationTime != nil {
//            defaults.setObject(creationTime!, forKey: UserFields.date)
//        }
//    }
//    
//    class func removeCurrenUserFromDefaults() {
//        
//        let defaults = NSUserDefaults.standardUserDefaults()
//        
//        defaults.removeObjectForKey(UserFields.id)
//        defaults.removeObjectForKey(UserFields.username)
//        defaults.removeObjectForKey(UserFields.email)
//        defaults.removeObjectForKey(UserFields.followerCount)
//        defaults.removeObjectForKey(UserFields.followingCount)
//        defaults.removeObjectForKey(UserFields.upCount)
//        defaults.removeObjectForKey(UserFields.postCount)
//        defaults.removeObjectForKey(UserFields.date)
//    }
    
}
