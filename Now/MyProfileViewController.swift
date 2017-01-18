//
//  MyProfileViewController.swift
//  Now
//
//  Created by Florian Bienefelt on 7/20/16.
//  Copyright © 2016 Florian Bienefelt. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import Fusuma

class MyProfileViewController: UIViewController, FusumaDelegate {
    
    // Model
    var currentUser: User?
    
    // Private properties
    private var ref: FIRDatabaseReference!
    private var storageRef: FIRStorageReference!
    
    // Storyboard Outlets
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var ProfilePictureImageView: UIImageView!
    @IBOutlet weak var UsernameLabel: UILabel!
    @IBOutlet weak var FollowingButtonOutlet: UIButton!
    @IBOutlet weak var FollowersButtonOutlet: UIButton!
    
    // Storyboard Actions
    @IBAction func FollowersButton(sender: UIButton) {
        performSegueWithIdentifier(Storyboard.ShowFollowSegue, sender: sender)
    }
    
    @IBAction func FollowingButton(sender: UIButton) {
        performSegueWithIdentifier(Storyboard.ShowFollowSegue, sender: sender)
    }
    
    @IBAction func ChangePictureButton(sender: UIButton) {
        let fusuma = FusumaViewController()
        fusuma.delegate = self
        fusumaCropImage = true
        
        presentViewController(fusuma, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if currentUser != nil {
            ref = FIRDatabase.database().reference()
            storageRef = FIRStorage.storage().reference()
            getCurrentUserFromFirebase() { [weak weakSelf = self] in
                weakSelf?.setOutlets()
            }
            
        }
    }
    
    // Setup
    private func setOutlets() {
        if currentUser != nil {
            UsernameLabel.text = currentUser!.username
            if currentUser!.followerCount! - 1 == 1 {
                FollowersButtonOutlet.setTitle(String(currentUser!.followerCount! - 1) + " Follower", forState: .Normal)
            } else {
                FollowersButtonOutlet.setTitle(String(currentUser!.followerCount! - 1) + " Followers", forState: .Normal)
            }
            FollowingButtonOutlet.setTitle(String(currentUser!.followingCount! - 1) + " Following", forState: .Normal)
            setCurrentUserImage()
            // set profile picture
        }
    }
    
    
    // General Functions
    private func getCurrentUserFromFirebase(withClosure closure : () -> Void) {
        if let currentAuthUser = FIRAuth.auth()?.currentUser {
            ref.child("users").child(currentAuthUser.uid).observeSingleEventOfType(.Value) { [weak weakSelf = self] (userSnapshot: FIRDataSnapshot) -> Void in
                let newCurrentUser = User(snapshot: userSnapshot)
                weakSelf?.currentUser = newCurrentUser
                closure()
            }
        }
    }
    
    
    // Fusuma Camera functions
    // Return the image which is selected from camera roll or is taken via the camera.
    func fusumaImageSelected(image: UIImage) {
        setNewImage(image)
    }
    
    // Return the image but called after is dismissed.
    func fusumaDismissedWithImage(image: UIImage) {
        setNewImage(image)
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: NSURL) {
        
        print("Called just after a video has been selected.")
    }
    
    // When camera roll is not authorized, this method is called.
    func fusumaCameraRollUnauthorized() {
        
        print("Camera roll unauthorized")
    }
    
    private func setNewImage(image: UIImage) {
        if let theCurrentUser = FIRAuth.auth()?.currentUser {
            ProfilePictureImageView.image = image
            let largeImageData = compressImage(image)
            let smallImageData = compressImage(image, small: true)
            let largeImagePath = "users/" + theCurrentUser.uid + "_large.jpg"
            let smallImagePath = "users/" + theCurrentUser.uid + "_small.jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            // show network activity indicator and push both images to firebase
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            storageRef.child(largeImagePath)
                .putData(largeImageData, metadata: metadata) { (metadata, error) in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    
                    if let error = error {
                        print("Error uploading: \(error)")
                        return
                    }
            }
            storageRef.child(smallImagePath)
                .putData(smallImageData, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print("Error uploading: \(error)")
                        return
                    }
            }
        }
    }
    
    private func setCurrentUserImage() {
        // Download the small image
        if let theCurrentUser = FIRAuth.auth()?.currentUser {
            ActivityIndicator.startAnimating()
            storageRef.child("users").child(theCurrentUser.uid + "_large.jpg").dataWithMaxSize(INT64_MAX) { [weak weakSelf = self] (data, error) in
                weakSelf?.ActivityIndicator.stopAnimating()
                if let error = error {
                    print("Error downloading: \(error)")
                    
                    if error.localizedDescription.containsString("does not exist") {
                        weakSelf?.ProfilePictureImageView.image = UIImage(named: "placeholder-user-photo.png")
                    }
                    return
                }
                if data != nil {
                    weakSelf?.ProfilePictureImageView.image = UIImage(data: data!)
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.ShowFollowSegue:
                if let vc = segue.destinationViewController as? UserTableViewController {
                    if let sendingButton = sender as? UIButton {
                        if currentUser != nil {
                            vc.userId = currentUser!.id!
                            if sendingButton.currentTitle!.containsString("Following") {
                                vc.forFollowing = true
                            } else if sendingButton.currentTitle!.containsString("Follower") {
                                vc.forFollowers = true
                            }
                        }
                    }
                }
            default: break
            }
        }
    }
    
    
    private struct Storyboard {
        static let ShowFollowSegue = "Show Follows"
    }
    
}
