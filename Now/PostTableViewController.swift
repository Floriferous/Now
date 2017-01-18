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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class PostTableViewController: UITableViewController {
    
    // Model
    var firebasePosts: [(snapshot: FIRDataSnapshot, image: Data)]! = []
    var userLocation: CLLocation?
    var forSpecificUser = false
    var forUserUps = false
    var userId: String?
    
    // Private properties
    fileprivate var ref: FIRDatabaseReference!
    fileprivate var storageRef: FIRStorageReference!
    fileprivate var _refHandleAdded: FIRDatabaseHandle!
    fileprivate var _refHandleRemoved: FIRDatabaseHandle!
    fileprivate var _refHandleChanged: FIRDatabaseHandle!
    fileprivate var _refHandleUser: FIRDatabaseHandle!
    
    
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
    
    override func viewWillAppear(_ animated: Bool) {
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
    
    
    fileprivate func indexForKey(_ key: String) -> Int {
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
    
    fileprivate func getImageForPostID(_ id: String, withClosure closure: @escaping (_ data: Data) -> Void) {
        // Download the small image
        storageRef.child("posts").child(id + "_small.jpg").data(withMaxSize: INT64_MAX) { (data, error) in
            if let error = error {
                print("Error downloading: \(error)")
                return
            }
            if data != nil {
                closure(data!)
            }
        }
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        if forSpecificUser {
            if userId != nil {
                ref.child("posts").queryOrdered(byChild: PostFields.userId).queryEqual(toValue: userId!).removeObserver(withHandle: _refHandleAdded)
            }
        } else if forUserUps {
            if userId != nil {
                ref.child("users").child(userId!).child(UserFields.ups).removeObserver(withHandle: _refHandleAdded)
            }
        } else {
            ref.child("posts").queryOrdered(byChild: "date").removeObserver(withHandle: _refHandleAdded)
            ref.child("posts").queryOrdered(byChild: "date").removeObserver(withHandle: _refHandleRemoved)
        }
    }
    
    deinit {
        if forSpecificUser {
            
        } else if forUserUps {
            
        } else {
            ref.child("posts").queryOrdered(byChild: "date").removeObserver(withHandle: _refHandleChanged)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // if there are posts
        if (firebasePosts.count > 0)
        {
            tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
            tableView.backgroundView   = nil;
        }
        else
        {
            let label = UILabel(frame: CGRect(x: 0, y: 0,
                width: tableView.bounds.size.width,
                height: tableView.bounds.size.height))
            
            label.text = "Looks a little empty to me!"
            label.numberOfLines = 0
            label.textColor = UIColor.black
            label.textAlignment = NSTextAlignment.center
            tableView.backgroundView = label
            tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        }
        
        return firebasePosts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.PostCellName, for: indexPath)
        
        if let postCell = cell as? PostTableViewCell {
            postCell.userLocation = userLocation
            postCell.post = Post(snapshot: firebasePosts[indexPath.row].snapshot)
            postCell.postImage = UIImage(data: firebasePosts[indexPath.row].image)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if forSpecificUser && userId == FIRAuth.auth()?.currentUser!.uid {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let postId = firebasePosts[indexPath.row].snapshot.key
            if let currentUserId = FIRAuth.auth()?.currentUser!.uid {
                
                // Delete ups from all upping users
                ref.child("posts").child(postId).child("ups").observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot) in
                    
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
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                storageRef.child("posts").child(postId + "_large.jpg").delete(completion: { (error) in
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    print(error)
                })
                storageRef.child("posts").child(postId + "_small.jpg").delete(completion: { (error) in
                    print(error)
                })
                
                firebasePosts.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
        }
    }
    
    // Firebase Functions
    fileprivate func getPostsForSpecificUser() {
        if userId != nil {
            // Check added posts
            _refHandleAdded = ref.child("posts").queryOrdered(byChild: PostFields.userId).queryEqual(toValue: userId!).observe(.childAdded) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
                if weakSelf != nil {
                    
                    // check if this post still exists
                    if snapshot.value is NSNull {
                    } else {
                        if weakSelf!.indexForKey(snapshot.key) < 0 {
                            weakSelf!.firebasePosts.insert((snapshot, Data()), at: 0)
                            weakSelf!.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                            
                            // download image and add it asynchronously
                            weakSelf!.getImageForPostID(snapshot.key) { [weak weakSelf = self] (data) in
                                if weakSelf != nil {
                                    let snapIndex = IndexPath(row: weakSelf!.indexForKey(snapshot.key), section: 0)
                                    
                                    // verify if cell index is still the same after download time
                                    if weakSelf?.firebasePosts[snapIndex.row].snapshot.key == snapshot.key {
                                        // add image to the firebase post and reload row
                                        weakSelf!.firebasePosts[snapIndex.row] = (snapshot, data)
                                        weakSelf!.tableView.reloadRows(at: [snapIndex], with: .automatic)
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
    
    fileprivate func getPostsForUserUps() {
        if userId != nil {
            // Check added posts
            
            _refHandleAdded = ref.child("users").child(userId!).child(UserFields.ups).observe(.childAdded) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
                if weakSelf != nil {
                    let postKey = snapshot.key
                    weakSelf!.ref.child("posts").child(postKey).observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot) -> Void in
                        
                        // check if post still exists
                        if snapshot.value is NSNull {
                            
                        } else {
                            // insert textual data
                            if weakSelf!.indexForKey(snapshot.key) < 0 {
                                weakSelf!.firebasePosts.insert((snapshot, Data()), at: 0)
                                weakSelf!.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                                
                                // download image and add it asynchronously
                                weakSelf!.getImageForPostID(snapshot.key) { [weak weakSelf = self] (data) in
                                    if weakSelf != nil {
                                        let snapIndex = IndexPath(row: weakSelf!.indexForKey(snapshot.key), section: 0)
                                        
                                        // verify if cell index is still the same after download time
                                        if weakSelf?.firebasePosts[snapIndex.row].snapshot.key == snapshot.key {
                                            // add image to the firebase post and reload row
                                            weakSelf!.firebasePosts[snapIndex.row] = (snapshot, data)
                                            weakSelf!.tableView.reloadRows(at: [snapIndex], with: .automatic)
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
    
    
    fileprivate func getPostsForAllUsers() {
        // Check added posts
        _refHandleAdded = ref.child("posts").queryOrdered(byChild: "date").observe(.childAdded) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
            
            // add textual data without image
            if weakSelf != nil {
                if weakSelf!.indexForKey(snapshot.key) < 0 {
                    weakSelf!.firebasePosts.insert((snapshot, Data()), at: 0)
                    weakSelf!.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    
                    //download image
                    weakSelf!.getImageForPostID(snapshot.key) { [weak weakSelf = self] (data) in
                        if weakSelf != nil {
                            let snapIndex = IndexPath(row: weakSelf!.indexForKey(snapshot.key), section: 0)
                            
                            // verify if cell index is still the same after download time
                            if weakSelf?.firebasePosts[snapIndex.row].snapshot.key == snapshot.key {
                                // add image to the firebase post and reload row
                                weakSelf!.firebasePosts[snapIndex.row] = (snapshot, data)
                                weakSelf!.tableView.reloadRows(at: [snapIndex], with: .automatic)
                            }
                        }
                    }
                }
            }
        }
        // Check removed posts
        _refHandleRemoved = ref.child("posts").queryOrdered(byChild: "date").observe(.childRemoved) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
            if weakSelf != nil {
                let index = weakSelf!.indexForKey(snapshot.key)
                weakSelf!.firebasePosts.remove(at: index)//insert((snapshot, NSData()), atIndex: 0)
                weakSelf!.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            }
        }
        
        // Check changed posts
        _refHandleChanged = ref.child("posts").queryOrdered(byChild: "date").observe(.childChanged) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
            if weakSelf != nil {
                let snapIndex = IndexPath(row: weakSelf!.indexForKey(snapshot.key), section: 0)
                if snapIndex.row >= 0 {
                    // keep same image
                    weakSelf!.firebasePosts[snapIndex.row] = (snapshot, weakSelf!.firebasePosts[snapIndex.row].image)
                    weakSelf!.tableView.reloadRows(at: [snapIndex], with: .automatic)
                }
            }
        }
    }
    
    
    // Prepare for Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.ShowPostSegue:
                if let vc = segue.destination as? PostViewController {
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
    fileprivate func addUnwindButton() {
        // Disable unwind button if this VC is early in the stack
        if self.navigationController?.viewControllers.count <= 2 {
            self.navigationItem.rightBarButtonItem = nil
        } else {
            let unwindButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(unwind(_:)))
            unwindButton.setTitleTextAttributes([NSFontAttributeName: UIFont.fontAwesomeOfSize(30)], for: .Normal)
            unwindButton.title = String.fontAwesomeIconWithName(.Times)
            self.navigationItem.rightBarButtonItem = unwindButton
        }
    }
    @objc fileprivate func unwind(_ sender: AnyObject?) {
        performSegue(withIdentifier: Storyboard.UnwindSegue, sender: nil)
    }
    
    // Storyboard constants
    fileprivate struct Storyboard {
        static let PostCellName = "Post Cell"
        static let ShowPostSegue = "Show Post"
        static let UnwindSegue = "Unwind To Map"
    }
}
