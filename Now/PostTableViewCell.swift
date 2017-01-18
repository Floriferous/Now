//
//  PostTableViewCell.swift
//  Now
//
//  Created by Florian Bienefelt on 7/15/16.
//  Copyright © 2016 Now. All rights reserved.
//


import UIKit
import MapKit

class PostTableViewCell: UITableViewCell
{
    
    // Model
    var post: Post? {
        didSet {
            updateUI()
        }
    }
    var userLocation: CLLocation?
    var postImage: UIImage? {
        didSet {
            if post != nil && (postImage != Data()) && postImage != nil {
                PostImageView.image = postImage!
            },
        }
    }
    
    // Storyboard outlets and actions
    @IBOutlet weak var PostImageView: UIImageView!
    @IBOutlet weak var PostDistance: UILabel!
    @IBOutlet weak var PostCreated: UILabel!
    @IBOutlet weak var PostLikeCount: UILabel!
    @IBOutlet weak var PostTitle: UILabel!
    
    // Setup
    fileprivate func updateUI() {
        // reset info
        PostImageView?.image = nil
        PostDistance?.text = nil
        PostTitle?.text = nil
        PostCreated?.text = nil
        
        if post != nil {
            PostTitle?.text = post!.title
            
            if userLocation != nil {
                let postLocation = CLLocation(latitude: post!.latitude!, longitude: post!.longitude!)
                if postLocation.distance(from: userLocation!) < 1000 {
                    PostDistance?.text = String(Int(round(postLocation.distance(from: userLocation!) / 10) * 10)) + "m away"
                } else if postLocation.distance(from: userLocation!) < 100000 {
                    PostDistance?.text = String((round(postLocation.distance(from: userLocation!) / 100) * 100) / 1000) + "km away"
                } else {
                    PostDistance?.text = String(Int((round(postLocation.distance(from: userLocation!) / 1000) * 1000) / 1000)) + "km away"
                }
            } else {
                PostDistance.text = ""
            }
            
            if post!.creationTime != nil {
                PostCreated?.text = timeAgoSinceDate(post!.creationTime!, numericDates: true)
            }
            
            PostLikeCount?.text = "+" + String(post!.upCount! - 1)
        }
    }
}
