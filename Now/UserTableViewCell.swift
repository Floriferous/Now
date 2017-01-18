//
//  UserTableViewCell.swift
//  Now
//
//  Created by Florian Bienefelt on 7/18/16.
//  Copyright © 2016 Florian Bienefelt. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {
    
    // Model
    var user: User? {
        didSet {
            updateUI()
        }
    }
    var ProfilePicture: UIImage? {
        didSet {
            UserImageView.image = nil
            if user != nil && ProfilePicture != NSData() && ProfilePicture != nil {
                UserImageView.image = ProfilePicture
            } else {
                UserImageView.image = UIImage(named: "placeholder-user-photo.png")
            }
        }
    }
    
    // Storyboard outlets and actions
    @IBOutlet weak var UsernameLabel: UILabel!
    @IBOutlet weak var FollowerCountLabel: UILabel!
    @IBOutlet weak var UserImageView: UIImageView!
    @IBOutlet weak var FollowButtonOutlet: UIButton!
    @IBAction func FollowButton(sender: UIButton) {
    }
    
    // Setup
    private func updateUI() {
        
        // reset info
        UsernameLabel.text = nil
        FollowerCountLabel.text = nil
        
        if user != nil {
            UsernameLabel?.text = user!.username!
            
            if user!.followerCount != nil {
                FollowerCountLabel?.text = String(user!.followerCount!) + " Followers"
            } else {
                FollowerCountLabel?.text = "0 Followers"
            }
        }
    }
}