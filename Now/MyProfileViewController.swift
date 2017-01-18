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
    fileprivate var ref: FIRDatabaseReference!
    fileprivate var storageRef: FIRStorageReference!
    
    // Storyboard Outlets
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var ProfilePictureImageView: UIImageView!
    @IBOutlet weak var UsernameLabel: UILabel!
    @IBOutlet weak var FollowingButtonOutlet: UIButton!
    @IBOutlet weak var FollowersButtonOutlet: UIButton!
    
    // Storyboard Actions
    @IBAction func FollowersButton(_ sender: UIButton) {
        performSegue(withIdentifier: Storyboard.ShowFollowSegue, sender: sender)
    }
    
    @IBAction func FollowingButton(_ sender: UIButton) {
        performSegue(withIdentifier: Storyboard.ShowFollowSegue, sender: sender)
    }
    
    @IBAction func ChangePictureButton(_ sender: UIButton) {
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
    fileprivate func setOutlets() {
        if currentUser != nil {
            UsernameLabel.text = currentUser!.username
            if currentUser!.followerCount! - 1 == 1 {
                FollowersButtonOutlet.setTitle(String(currentUser!.followerCount! - 1) + " Follower", for: UIControlState())
            } else {
                FollowersButtonOutlet.setTitle(String(currentUser!.followerCount! - 1) + " Followers", for: UIControlState())
            }
            FollowingButtonOutlet.setTitle(String(currentUser!.followingCount! - 1) + " Following", for: UIControlState())
            setCurrentUserImage()
            // set profile picture
        }
    }
    
    
    // General Functions
    fileprivate func getCurrentUserFromFirebase(withClosure closure : @escaping () -> Void) {
        if let currentAuthUser = FIRAuth.auth()?.currentUser {
            ref.child("users").child(currentAuthUser.uid).observeSingleEvent(of: .value) { [weak weakSelf = self] (userSnapshot: FIRDataSnapshot) -> Void in
                let newCurrentUser = User(snapshot: userSnapshot)
                weakSelf?.currentUser = newCurrentUser
                closure()
            }
        }
    }
    
    
    // Fusuma Camera functions
    // Return the image which is selected from camera roll or is taken via the camera.
    func fusumaImageSelected(_ image: UIImage) {
        setNewImage(image)
    }
    
    // Return the image but called after is dismissed.
    func fusumaDismissedWithImage(_ image: UIImage) {
        setNewImage(image)
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: URL) {
        
        print("Called just after a video has been selected.")
    }
    
    // When camera roll is not authorized, this method is called.
    func fusumaCameraRollUnauthorized() {
        
        print("Camera roll unauthorized")
    }
    
    fileprivate func setNewImage(_ image: UIImage) {
        if let theCurrentUser = FIRAuth.auth()?.currentUser {
            ProfilePictureImageView.image = image
            let largeImageData = compressImage(image)
            let smallImageData = compressImage(image, small: true)
            let largeImagePath = "users/" + theCurrentUser.uid + "_large.jpg"
            let smallImagePath = "users/" + theCurrentUser.uid + "_small.jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            // show network activity indicator and push both images to firebase
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            storageRef.child(largeImagePath)
                .put(largeImageData, metadata: metadata) { (metadata, error) in
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    
                    if let error = error {
                        print("Error uploading: \(error)")
                        return
                    }
            }
            storageRef.child(smallImagePath)
                .put(smallImageData, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print("Error uploading: \(error)")
                        return
                    }
            }
        }
    }
    
    fileprivate func setCurrentUserImage() {
        // Download the small image
        if let theCurrentUser = FIRAuth.auth()?.currentUser {
            ActivityIndicator.startAnimating()
            storageRef.child("users").child(theCurrentUser.uid + "_large.jpg").data(withMaxSize: INT64_MAX) { [weak weakSelf = self] (data, error) in
                weakSelf?.ActivityIndicator.stopAnimating()
                if let error = error {
                    print("Error downloading: \(error)")
                    
                    if error.localizedDescription.contains("does not exist") {
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.ShowFollowSegue:
                if let vc = segue.destination as? UserTableViewController {
                    if let sendingButton = sender as? UIButton {
                        if currentUser != nil {
                            vc.userId = currentUser!.id!
                            if sendingButton.currentTitle!.contains("Following") {
                                vc.forFollowing = true
                            } else if sendingButton.currentTitle!.contains("Follower") {
                                vc.forFollowers = true
                            }
                        }
                    }
                }
            default: break
            }
        }
    }
    
    
    fileprivate struct Storyboard {
        static let ShowFollowSegue = "Show Follows"
    }
    
}
