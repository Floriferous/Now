//
//  Post.swift
//  Now
//
//  Created by Florian Bienefelt on 7/12/16.
//  Copyright © 2016 Now. All rights reserved.
//

import Foundation
import Firebase

class Post {
    fileprivate(set) var id: String?
    fileprivate(set) var userId: String?
    fileprivate(set) var latitude: Double?
    fileprivate(set) var longitude: Double?
    fileprivate(set) var title: String?
    fileprivate(set) var description: String?
    fileprivate(set) var image: String?
    fileprivate(set) var creationTime: Date?
    fileprivate(set) var upCount: Int?

    // Load data from snapshot into Post
    init(snapshot: FIRDataSnapshot!) {
        id = String(snapshot.key)
        title = snapshot.value![PostFields.title] as? String
        description = snapshot.value![PostFields.description] as? String
        upCount = Int(snapshot.childSnapshot(forPath: PostFields.ups).childrenCount)
        latitude = snapshot.value![PostFields.latitude] as? Double
        longitude = snapshot.value![PostFields.longitude] as? Double
        userId = snapshot.value![PostFields.userId] as? String
        if let time = snapshot.value![PostFields.date] as? Double {
            creationTime = Date(timeIntervalSince1970: time/1000)
        }
    }
    
    // Create Post array
    class func parseFromSnapshot(_ snapshot: FIRDataSnapshot) -> [Post] {
        var posts = [Post]()
        for child in snapshot.children {
            let post = Post.init(snapshot: child as! FIRDataSnapshot)
            posts.insert(post, at: 0)
        }
        return posts
    }
}
