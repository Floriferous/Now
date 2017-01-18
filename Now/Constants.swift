//
//  Constants.swift
//  Now
//
//  Created by Florian Bienefelt on 7/18/16.
//  Copyright © 2016 Florian Bienefelt. All rights reserved.
//

import Foundation
import UIKit

struct GlobalColors {
    static let alizarinRed = UIColor.init(red: 231.0/255.0, green: 76.0/255.0, blue: 60.0/255.0, alpha: 1.0)
}

struct UserDefaultKeys {
    static let currentUser = "currentUser"
}

struct PostFields {
    static let id = "id"
    static let title = "title"
    static let imageURL = "imageurl"
    static let description = "description"
    static let ups = "ups"
    static let latitude = "latitude"
    static let longitude = "longitude"
    static let date = "date"
    static let userId = "uid"
}

struct UserFields {
    static let id = "id"
    static let username = "username"
    static let email = "email"
    static let imageURL = "imageurl"
    static let followers = "followers"
    static let posts = "posts"
    static let following = "following"
    static let ups = "ups"
    static let date = "date"
    
    static let followerCount = "followercount"
    static let followingCount = "followingcount"
    static let upCount = "upcount"
    static let postCount = "postcount"

}

// Image compression algorithm
func compressImage(_ image: UIImage, small: Bool = false) -> Data {
    var actualHeight = image.size.height
    var actualWidth = image.size.width
    var maxHeight = CGFloat(800.0)
    var maxWidth = CGFloat(800.0)
    var imgRatio = actualWidth / actualHeight
    let maxRatio = maxWidth / maxHeight
    var compressionQuality = CGFloat(0.5) //50 percent compression
    
    if small {
        maxHeight = CGFloat(800.0 / 3)
        maxWidth = CGFloat(800.0 / 3)
        compressionQuality = CGFloat(0.25)
    }
    
    if (actualHeight > maxHeight || actualWidth > maxWidth) {
        if (imgRatio < maxRatio) {
            //adjust width according to maxHeight
            imgRatio = maxHeight / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = maxHeight;
        }
        else if (imgRatio > maxRatio) {
            //adjust height according to maxWidth
            imgRatio = maxWidth / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = maxWidth;
        }
        else {
            actualHeight = maxHeight;
            actualWidth = maxWidth;
        }
    }
    
    let rect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
    UIGraphicsBeginImageContext(rect.size)
    image.draw(in: rect)
    let img = UIGraphicsGetImageFromCurrentImageContext()
    let imageData = UIImageJPEGRepresentation(img!, compressionQuality)
    UIGraphicsEndImageContext()
    if imageData != nil {
        return imageData!
    }
    
    return Data()
}


// Time formatting function
func timeAgoSinceDate(_ date:Date, numericDates:Bool) -> String {
    let calendar = Calendar.current
    let now = Date()
    let earliest = (now as NSDate).earlierDate(date)
    let latest = (earliest == now) ? date : now
    let components:DateComponents = (calendar as NSCalendar).components([NSCalendar.Unit.minute , NSCalendar.Unit.hour , NSCalendar.Unit.day , NSCalendar.Unit.weekOfYear , NSCalendar.Unit.month , NSCalendar.Unit.year , NSCalendar.Unit.second], from: earliest, to: latest, options: NSCalendar.Options())
    
    if (components.year! >= 2) {
        return "\(components.year) years ago"
    } else if (components.year! >= 1){
        if (numericDates){
            return "1 year ago"
        } else {
            return "Last year"
        }
    } else if (components.month! >= 2) {
        return "\(components.month) months ago"
    } else if (components.month! >= 1){
        if (numericDates){
            return "1 month ago"
        } else {
            return "Last month"
        }
    } else if (components.weekOfYear! >= 2) {
        return "\(components.weekOfYear) weeks ago"
    } else if (components.weekOfYear! >= 1){
        if (numericDates){
            return "1 week ago"
        } else {
            return "Last week"
        }
    } else if (components.day! >= 2) {
        return "\(components.day) days ago"
    } else if (components.day! >= 1){
        if (numericDates){
            return "1 day ago"
        } else {
            return "Yesterday"
        }
    } else if (components.hour! >= 2) {
        return "\(components.hour) hours ago"
    } else if (components.hour! >= 1){
        if (numericDates){
            return "1 hour ago"
        } else {
            return "An hour ago"
        }
    } else if (components.minute! >= 2) {
        return "\(components.minute) minutes ago"
    } else if (components.minute! >= 1){
        if (numericDates){
            return "1 minute ago"
        } else {
            return "A minute ago"
        }
    } else if (components.second! >= 3) {
        return "\(components.second) seconds ago"
    } else {
        return "Just now"
    }
}
