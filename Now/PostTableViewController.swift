//
//  ListViewControllerTableViewController.swift
//  Now
//
//  Created by Florian Bienefelt on 7/12/16.
//  Copyright © 2016 Now. All rights reserved.
//

// Display posts in a list view

import UIKit
import CoreLocation
import FontAwesome_swift
import Firebase
import FirebaseAuth

class PostTableViewController: UITableViewController {
    
    // Model
    var firebasePosts: [(snapshot: FIRDataSnapshot, image: NSData)]! = []
    var userLocation: CLLocation?
    var forSpecificUser = false
    var forUserUps = false
    var userId: String?
    
    // Private properties
    private var ref: FIRDatabaseReference!
    private var storageRef: FIRStorageReference!
    private var _refHandleAdded: FIRDatabaseHandle!
    private var _refHandleRemoved: FIRDatabaseHandle!
    private var _refHandleChanged: FIRDatabaseHandle!
    private var _refHandleUser: FIRDatabaseHandle!
    
    
    // Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        addUnwindButton()
        ref = FIRDatabase.database().reference()
        storageRef = FIRStorage.storage().reference()
        
        //tableView.dataSource =
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if forSpecificUser {
            // if you want to see a list of posts for a specific user
            getPostsForSpecificUser()
        } else if forUserUps {
            // if you want to see a list of posts a user has upvoted
            getPostsForUserUps()
        } else {
            // if you want to see a list of posts from all users
            getPostsForAllUsers()
        }
    }
    
    
    private func indexForKey(key: String) -> Int {
        // if the key doesn't exist
        if key == "" {
            return -1
        }
        // normal behavior
        if firebasePosts.count > 0 {
            for i in 0...firebasePosts.count - 1 {
                if key == firebasePosts[i].snapshot.key {
                    return i
                }
            }
        }
        // didn't find a match
        return -1
    }
    
    private func getImageForPostID(id: String, withClosure closure: (data: NSData) -> Void) {
        // Download the small image
        storageRef.child("posts").child(id + "_small.jpg").dataWithMaxSize(INT64_MAX) { (data, error) in
            if let error = error {
                print("Error downloading: \(error)")
                return
            }
            if data != nil {
                closure(data: data!)
            }
        }
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        if forSpecificUser {
            if userId != nil {
                ref.child("posts").queryOrderedByChild(PostFields.userId).queryEqualToValue(userId!).removeObserverWithHandle(_refHandleAdded)
            }
        } else if forUserUps {
            if userId != nil {
                ref.child("users").child(userId!).child(UserFields.ups).removeObserverWithHandle(_refHandleAdded)
            }
        } else {
            ref.child("posts").queryOrderedByChild("date").removeObserverWithHandle(_refHandleAdded)
            ref.child("posts").queryOrderedByChild("date").removeObserverWithHandle(_refHandleRemoved)
        }
    }
    
    deinit {
        if forSpecificUser {
            
        } else if forUserUps {
            
        } else {
            ref.child("posts").queryOrderedByChild("date").removeObserverWithHandle(_refHandleChanged)
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // if there are posts
        if (firebasePosts.count > 0)
        {
            tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            tableView.backgroundView   = nil;
        }
        else
        {
            let label = UILabel(frame: CGRect(x: 0, y: 0,
                width: tableView.bounds.size.width,
                height: tableView.bounds.size.height))
            
            label.text = "Looks a little empty to me!"
            label.numberOfLines = 0
            label.textColor = UIColor.blackColor()
            label.textAlignment = NSTextAlignment.Center
            tableView.backgroundView = label
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        }
        
        return firebasePosts.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.PostCellName, forIndexPath: indexPath)
        
        if let postCell = cell as? PostTableViewCell {
            postCell.userLocation = userLocation
            postCell.post = Post(snapshot: firebasePosts[indexPath.row].snapshot)
            postCell.postImage = UIImage(data: firebasePosts[indexPath.row].image)
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if forSpecificUser && userId == FIRAuth.auth()?.currentUser!.uid {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let postId = firebasePosts[indexPath.row].snapshot.key
            if let currentUserId = FIRAuth.auth()?.currentUser!.uid {
                
                // Delete ups from all upping users
                ref.child("posts").child(postId).child("ups").observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
                    
                    for child in snapshot.children.allObjects as! [FIRDataSnapshot] {
                        let uppingUserId = child.key
                        if uppingUserId != "init" {
                            self.ref.child("users").child(uppingUserId).child(UserFields.ups).child(postId).removeValue()
                        }
                    }
                }
                // Delete post from posts
                ref.child("posts").child(postId).removeValue()
                // Delete post from current user/posts
                ref.child("users").child(currentUserId).child("posts").child(postId).removeValue()
                // Delete the 2 pictures from storage/posts
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                storageRef.child("posts").child(postId + "_large.jpg").deleteWithCompletion({ (error) in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    print(error)
                })
                storageRef.child("posts").child(postId + "_small.jpg").deleteWithCompletion({ (error) in
                    print(error)
                })
                
                firebasePosts.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
            
        }
    }
    
    // Firebase Functions
    private func getPostsForSpecificUser() {
        if userId != nil {
            // Check added posts
            _refHandleAdded = ref.child("posts").queryOrderedByChild(PostFields.userId).queryEqualToValue(userId!).observeEventType(.ChildAdded) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
                if weakSelf != nil {
                    
                    // check if this post still exists
                    if snapshot.value is NSNull {
                    } else {
                        if weakSelf!.indexForKey(snapshot.key) < 0 {
                            weakSelf!.firebasePosts.insert((snapshot, NSData()), atIndex: 0)
                            weakSelf!.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
                            
                            // download image and add it asynchronously
                            weakSelf!.getImageForPostID(snapshot.key) { [weak weakSelf = self] (data) in
                                if weakSelf != nil {
                                    let snapIndex = NSIndexPath(forRow: weakSelf!.indexForKey(snapshot.key), inSection: 0)
                                    
                                    // verify if cell index is still the same after download time
                                    if weakSelf?.firebasePosts[snapIndex.row].snapshot.key == snapshot.key {
                                        // add image to the firebase post and reload row
                                        weakSelf!.firebasePosts[snapIndex.row] = (snapshot, data)
                                        weakSelf!.tableView.reloadRowsAtIndexPaths([snapIndex], withRowAnimation: .Automatic)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Check changed posts
            
            
        }
    }
    
    private func getPostsForUserUps() {
        if userId != nil {
            // Check added posts
            
            _refHandleAdded = ref.child("users").child(userId!).child(UserFields.ups).observeEventType(.ChildAdded) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
                if weakSelf != nil {
                    let postKey = snapshot.key
                    weakSelf!.ref.child("posts").child(postKey).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) -> Void in
                        
                        // check if post still exists
                        if snapshot.value is NSNull {
                            
                        } else {
                            // insert textual data
                            if weakSelf!.indexForKey(snapshot.key) < 0 {
                                weakSelf!.firebasePosts.insert((snapshot, NSData()), atIndex: 0)
                                weakSelf!.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
                                
                                // download image and add it asynchronously
                                weakSelf!.getImageForPostID(snapshot.key) { [weak weakSelf = self] (data) in
                                    if weakSelf != nil {
                                        let snapIndex = NSIndexPath(forRow: weakSelf!.indexForKey(snapshot.key), inSection: 0)
                                        
                                        // verify if cell index is still the same after download time
                                        if weakSelf?.firebasePosts[snapIndex.row].snapshot.key == snapshot.key {
                                            // add image to the firebase post and reload row
                                            weakSelf!.firebasePosts[snapIndex.row] = (snapshot, data)
                                            weakSelf!.tableView.reloadRowsAtIndexPaths([snapIndex], withRowAnimation: .Automatic)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    private func getPostsForAllUsers() {
        // Check added posts
        _refHandleAdded = ref.child("posts").queryOrderedByChild("date").observeEventType(.ChildAdded) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
            
            // add textual data without image
            if weakSelf != nil {
                if weakSelf!.indexForKey(snapshot.key) < 0 {
                    weakSelf!.firebasePosts.insert((snapshot, NSData()), atIndex: 0)
                    weakSelf!.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
                    
                    //download image
                    weakSelf!.getImageForPostID(snapshot.key) { [weak weakSelf = self] (data) in
                        if weakSelf != nil {
                            let snapIndex = NSIndexPath(forRow: weakSelf!.indexForKey(snapshot.key), inSection: 0)
                            
                            // verify if cell index is still the same after download time
                            if weakSelf?.firebasePosts[snapIndex.row].snapshot.key == snapshot.key {
                                // add image to the firebase post and reload row
                                weakSelf!.firebasePosts[snapIndex.row] = (snapshot, data)
                                weakSelf!.tableView.reloadRowsAtIndexPaths([snapIndex], withRowAnimation: .Automatic)
                            }
                        }
                    }
                }
            }
        }
        // Check removed posts
        _refHandleRemoved = ref.child("posts").queryOrderedByChild("date").observeEventType(.ChildRemoved) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
            if weakSelf != nil {
                let index = weakSelf!.indexForKey(snapshot.key)
                weakSelf!.firebasePosts.removeAtIndex(index)//insert((snapshot, NSData()), atIndex: 0)
                weakSelf!.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
            }
        }
        
        // Check changed posts
        _refHandleChanged = ref.child("posts").queryOrderedByChild("date").observeEventType(.ChildChanged) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
            if weakSelf != nil {
                let snapIndex = NSIndexPath(forRow: weakSelf!.indexForKey(snapshot.key), inSection: 0)
                if snapIndex.row >= 0 {
                    // keep same image
                    weakSelf!.firebasePosts[snapIndex.row] = (snapshot, weakSelf!.firebasePosts[snapIndex.row].image)
                    weakSelf!.tableView.reloadRowsAtIndexPaths([snapIndex], withRowAnimation: .Automatic)
                }
            }
        }
    }
    
    
    // Prepare for Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.ShowPostSegue:
                if let vc = segue.destinationViewController as? PostViewController {
                    if let sendingCell = sender as? PostTableViewCell {
                        vc.post = sendingCell.post
                        vc.userLocation = userLocation
                        vc.navigationItem.title = sendingCell.post?.title
                    }
                }
            default: break
            }
        }
    }
    
    // The unwind button and its unwind action
    private func addUnwindButton() {
        // Disable unwind button if this VC is early in the stack
        if self.navigationController?.viewControllers.count <= 2 {
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
        static let PostCellName = "Post Cell"
        static let ShowPostSegue = "Show Post"
        static let UnwindSegue = "Unwind To Map"
    }
}
