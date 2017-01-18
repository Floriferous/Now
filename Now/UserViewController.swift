//
//  UserViewController.swift
//  Now
//
//  Created by Florian Bienefelt on 7/18/16.
//  Copyright © 2016 Florian Bienefelt. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class UserViewController: UIViewController {
    
    // Model
    var user: User?
    var currentUser: User?
    
    // Private properties
    private var ref: FIRDatabaseReference!
    private var storageRef: FIRStorageReference!
    private var _refHandleChanged: FIRDatabaseHandle!
    
    
    // Storyboard outlets and actions
    @IBOutlet weak var UsernameLabel: UILabel!
    @IBOutlet weak var FollowButtonOutlet: UIButton!
    @IBOutlet weak var FollowerCountLabel: UILabel!
    @IBOutlet weak var FollowingCountLabel: UILabel!
    @IBOutlet weak var ProfilePictureView: UIImageView!
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var PostCountOutlet: UIButton!
    @IBAction func PostCountButton(sender: UIButton) {
        performSegueWithIdentifier(Storyboard.ShowPostsSegue, sender: self)
    }
    @IBAction func FollowButton(sender: UIButton) {
        
        if let _ = FIRAuth.auth()?.currentUser {
            // up or downvote post
            getCurrentUserFromFirebase() { [weak weakSelf = self] in weakSelf?.checkIfUserFollows(true) }
        } else {
            performSegueWithIdentifier(Storyboard.LoginSegue, sender: self)
            return
        }
    }
    
    // Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        storageRef = FIRStorage.storage().reference()
        setOutlets()
        addUnwindButton()
        
        if user != nil {
            //observe changes in follower and following count
            _refHandleChanged = ref.child("users").child(user!.id!).observeEventType(.ChildChanged) { [weak weakSelf = self] (userSnapshot: FIRDataSnapshot) -> Void in
                // neglect other changes to this user data node (hypothesis: there aren't many other ones)
                if userSnapshot.key == UserFields.followers {
                    if userSnapshot.childrenCount - 1 == 1 {
                        weakSelf?.FollowerCountLabel.text = String(userSnapshot.childrenCount - 1) + " Follower"
                    } else {
                        weakSelf?.FollowerCountLabel.text = String(userSnapshot.childrenCount - 1) + " Followers"
                    }
                } else if userSnapshot.key == UserFields.following {
                    weakSelf?.FollowingCountLabel.text = String(userSnapshot.childrenCount - 1) + " Following"
                    
                }
            }
        }
    }
    
    deinit {
        if user != nil {
            ref.child("users").child(user!.id!).removeObserverWithHandle(_refHandleChanged)
        }
    }
    
    // Setup
    func setOutlets() {
        if user != nil {
            UsernameLabel.text = user!.username!
            if user!.followerCount! - 1 == 1 {
                FollowerCountLabel.text = String(user!.followerCount! - 1) + " Follower"
            } else {
                FollowerCountLabel.text = String(user!.followerCount! - 1) + " Followers"
            }
            FollowingCountLabel.text = String(user!.followingCount! - 1) + " Following"
            PostCountOutlet.setTitle(String(user!.postCount!) + " Posts", forState: .Normal)
            setFollowButton()
            setImage()
        }
    }
    
    private func setFollowButton() {
        if let _ = FIRAuth.auth()?.currentUser {
            // up or downvote post
            getCurrentUserFromFirebase() { [weak weakSelf = self] in weakSelf?.checkIfUserFollows(false) }
        }
    }
    
    private func checkIfUserFollows(buttonPressed: Bool) {
        if user != nil {
            if currentUser != nil {
                ref.child("users").child(user!.id!).child(UserFields.followers).child(currentUser!.id!).observeSingleEventOfType(.Value) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
                    print("snapshot")
                    print(snapshot.value)
                    if snapshot.value is NSNull && weakSelf != nil {
                        // not followerd by this user yet, -> follow
                        if buttonPressed {
                            // update followers in User
                            let currentUserId = [weakSelf!.currentUser!.id!: true]
                            weakSelf?.ref.child("users").child(self.user!.id!).child(UserFields.followers).updateChildValues(currentUserId)
                            // update following in current User
                            let userId = [weakSelf!.user!.id!: true]
                            weakSelf?.ref.child("users").child(self.currentUser!.id!).child(UserFields.following).updateChildValues(userId)
                            //update button
                            weakSelf?.FollowButtonOutlet.setTitle("Following", forState: .Normal)
                        } else {
                            print("checking follow")
                            // if just checking, set current follow value as button title
                            weakSelf?.FollowButtonOutlet.setTitle("Follow", forState: .Normal)
                        }
                    } else if weakSelf != nil {
                        // current user already follows this user -> unfollow him
                        if buttonPressed {
                            // remove follower from user
                            weakSelf?.ref.child("users").child(self.user!.id!).child(UserFields.followers).child(self.currentUser!.id!).removeValue()
                            // remove following from current user
                            weakSelf?.ref.child("users").child(self.currentUser!.id!).child(UserFields.following).child(self.user!.id!).removeValue()
                            weakSelf?.FollowButtonOutlet.setTitle("Follow", forState: .Normal)
                        } else {
                            print("checking following")
                            // if just checking, set current follow value as button title
                            weakSelf?.FollowButtonOutlet.setTitle("Following", forState: .Normal)
                        }
                    }
                }
            }
        }
    }
    
    private func getCurrentUserFromFirebase(withClosure closure : () -> Void) {
        if let currentAuthUser = FIRAuth.auth()?.currentUser {
            ref.child("users").child(currentAuthUser.uid).observeSingleEventOfType(.Value) { [weak weakSelf = self] (userSnapshot: FIRDataSnapshot) -> Void in
                let newCurrentUser = User(snapshot: userSnapshot)
                weakSelf?.currentUser = newCurrentUser
                closure()
            }
        }
    }
    
    private func setImage() {
        ActivityIndicator.startAnimating()
        // Download the large image
        if user != nil {
            storageRef.child("users").child(user!.id! + "_large.jpg").dataWithMaxSize(INT64_MAX) { [weak weakSelf = self] (data, error) in
                if let error = error {
                    print("Error downloading: \(error)")
                    return
                }
                if data != nil {
                    weakSelf?.ProfilePictureView.image = UIImage(data: data!)
                    weakSelf?.ActivityIndicator.stopAnimating()
                }
            }
        }
    }
    
    
    
    // Prepare for segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            if identifier == Storyboard.ShowPostsSegue {
                if let vc = segue.destinationViewController as? PostTableViewController {
                    if user != nil {
                        vc.forSpecificUser = true
                        vc.userId = user!.id!
                        vc.navigationItem.title = user!.username!
                    }
                }
            }
        }
    }
    
    // The unwind button and its unwind action
    private func addUnwindButton() {
        // Disable unwind button if this VC is early in the stack
        if self.navigationController?.viewControllers.count == 1 {
            self.navigationItem.rightBarButtonItem = nil
        } else {
            let unwindButton = UIBarButtonItem(title: "", style: .Plain, target: self, action: #selector(unwind(_:)))
            unwindButton.setTitleTextAttributes([NSFontAttributeName: UIFont.fontAwesomeOfSize(30)], forState: .Normal)
            unwindButton.title = String.fontAwesomeIconWithName(.Times)
            self.navigationItem.rightBarButtonItem = unwindButton
        }
    }
    @objc private func unwind(sender: AnyObject?) {
        performSegueWithIdentifier(Storyboard.UnwindSegue, sender: nil)
    }
    
    // Storyboard constants
    private struct Storyboard {
        static let ShowPostsSegue = "Show Posts"
        static let UnwindSegue = "Unwind To Map"
        static let LoginSegue = "Log In"
    }
}
