//
//  AddDescriptionViewController.swift
//  Now
//
//  Created by Florian Bienefelt on 7/13/16.
//  Copyright © 2016 Now. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseAuth

class AddDescriptionViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    // Model
    var newPostPicture: UIImage?
    var newPostLocation: CLLocationCoordinate2D?
    var currentUser: User?
    
    // Private properties
    fileprivate var ref: FIRDatabaseReference!
    fileprivate var storageRef: FIRStorageReference!
    
    // Storyboard outlets and actions
    @IBOutlet weak var PostTitle: UITextView!
    @IBOutlet weak var PostDescription: UITextView!
    @IBOutlet weak var TitlePlaceholder: UILabel!
    @IBOutlet weak var DescriptionPlaceHolder: UILabel!
    @IBOutlet weak var TitleCount: UILabel!
    @IBOutlet weak var DescriptionCount: UILabel!
    
    // Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        storageRef = FIRStorage.storage().reference()
        setOutlets()
    }
    
    // Setup
    fileprivate func setOutlets() {
        PostTitle.delegate = self
        PostDescription.delegate = self
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(hitDone(_:)))
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    func hitDone(_ sender: AnyObject?) {
        // Verify if user is logged in
        if let _ = FIRAuth.auth()?.currentUser {
            // is logged in
        } else {
            performSegue(withIdentifier: Storyboard.LoginSegue, sender: nil)
            return
        }
        
        // get current user before trying to create post
        getCurrentUserFromFirebase() { [weak weakSelf = self] in
            do {
                try self.createPost()
                weakSelf?.performSegue(withIdentifier: Storyboard.UnwindToMapSegue, sender: sender)
            } catch PostCreationError.locationError {
                // smth
            } catch PostCreationError.titleError {
                print("title error")
            } catch PostCreationError.descriptionError {
                print("description error")
            } catch {
                print("other error")
            }
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        switch textView {
        case PostTitle: TitleCount.text = String((PostTitle.text?.characters.count)!) + "/40"
        if PostTitle.text.characters.count > 0 {
            TitlePlaceholder.isHidden = true
        } else {
            TitlePlaceholder.isHidden = false
            }
        case PostDescription: DescriptionCount.text = String((PostDescription.text?.characters.count)!) + "/200"
        if PostDescription.text.characters.count > 0 {
            DescriptionPlaceHolder.isHidden = true
        } else {
            DescriptionPlaceHolder.isHidden = false
            }
        default: break
        }
    }
    
    // General functions
    fileprivate func createPost() throws {
        
        // Prepare data for the new post
        var data = [String: AnyObject]()
        
        
        // add user id of creator!!!
        // also add post id to user under users/uid/posts/
        
        
        guard 2...40 ~= Int((PostTitle.text?.characters.count)!) else {
            throw PostCreationError.titleError
        }
        data[PostFields.title] = PostTitle.text! as String as AnyObject?
        
        guard -90...90 ~= Double(newPostLocation!.latitude) else {
            throw PostCreationError.locationError
        }
        data[PostFields.latitude] = newPostLocation!.latitude as NSNumber
        
        guard -180...180 ~= Double(newPostLocation!.longitude) else {
            throw PostCreationError.locationError
        }
        data[PostFields.longitude] = newPostLocation!.longitude as NSNumber
        
        // Verify if user gave a description
        if let description = PostDescription.text {
            guard 0...200 ~= Int((PostDescription.text?.characters.count)!) else {
                throw PostCreationError.descriptionError
            }
            data[PostFields.description] = description as AnyObject?
        }
        if currentUser != nil {
            data[PostFields.userId] = currentUser!.id! as AnyObject?
            data[PostFields.date] = [".sv": "timestamp"]
            
            
            
            
            // initial up to make the upCount work with a ChildChanged event
            data[PostFields.ups] = ["init": true]
            // Push to firebase
            let newPostRef = ref.child("posts").childByAutoId()
            newPostRef.setValue(data)
            
            // Verify if image exists
            guard newPostPicture != nil else {
                throw PostCreationError.noImage
            }
            
            // prepare large and small images
            let largeImageData = compressImage(newPostPicture!)
            let smallImageData = compressImage(newPostPicture!, small: true)
            let largeImagePath = "posts/" + newPostRef.key + "_large.jpg"
            let smallImagePath = "posts/" + newPostRef.key + "_small.jpg"
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
            
            
            // add new post id to user
            let postId = [newPostRef.key: true]
            
            let userRef = ref.child("users").child(currentUser!.id!).child("posts")
            userRef.updateChildValues((postId))
        }
        
    }
    
    @objc fileprivate func updateCharacterCount(_ sender: AnyObject?) {
        if let textField = sender as? UITextField {
            switch textField {
            case PostTitle: TitleCount.text = String((PostTitle.text?.characters.count)!) + "/40"
            case PostDescription: DescriptionCount.text = String((PostDescription.text?.characters.count)!) + "/200"
            default: break
            }
        }
    }
    
    fileprivate func getCurrentUserFromFirebase(withClosure closure : @escaping () -> Void) {
        if let currentAuthUser = FIRAuth.auth()?.currentUser {
            ref.child("users").child(currentAuthUser.uid).observeSingleEvent(of: .value)
            { [weak weakSelf = self] (userSnapshot: FIRDataSnapshot) -> Void in
                if weakSelf != nil {
                    let newCurrentUser = User(snapshot: userSnapshot)
                    weakSelf!.currentUser = newCurrentUser
                    closure()
                }
            }
        }
    }
    
    // Image compression function
    
    
    
    
    // Post creation errors
    enum PostCreationError: Error {
        case titleError
        case descriptionError
        case locationError
        case noImage
    }
    
    // Storyboard constants
    fileprivate struct Storyboard {
        static let UnwindToMapSegue = "Unwind To Map"
        static let LoginSegue = "Log In"
    }
}
