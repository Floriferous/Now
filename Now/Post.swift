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
    private(set) var id: String?
    private(set) var userId: String?
    private(set) var latitude: Double?
    private(set) var longitude: Double?
    private(set) var title: String?
    private(set) var description: String?
    private(set) var image: String?
    private(set) var creationTime: NSDate?
    private(set) var upCount: Int?

    // Load data from snapshot into Post
    init(snapshot: FIRDataSnapshot!) {
        id = String(snapshot.key)
        title = snapshot.value![PostFields.title] as? String
        description = snapshot.value![PostFields.description] as? String
        upCount = Int(snapshot.childSnapshotForPath(PostFields.ups).childrenCount)
        latitude = snapshot.value![PostFields.latitude] as? Double
        longitude = snapshot.value![PostFields.longitude] as? Double
        userId = snapshot.value![PostFields.userId] as? String
        if let time = snapshot.value![PostFields.date] as? Double {
            creationTime = NSDate(timeIntervalSince1970: time/1000)
        }
    }
    
    // Create Post array
    class func parseFromSnapshot(snapshot: FIRDataSnapshot) -> [Post] {
        var posts = [Post]()
        for child in snapshot.children {
            let post = Post.init(snapshot: child as! FIRDataSnapshot)
            posts.insert(post, atIndex: 0)
        }
        return posts
    }
}