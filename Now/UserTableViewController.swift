//
//  ListViewControllerTableViewController.swift
//  Now
//
//  Created by Florian Bienefelt on 7/18/16.
//  Copyright © 2016 Now. All rights reserved.
//

// Display posts in a list view

import UIKit
import CoreLocation
import FontAwesome_swift
import Firebase

class UserTableViewController: UITableViewController {
    
    // Model
    var postId: String?
    
    var userId: String?
    var forFollowers = false
    var forFollowing = false
    
    // Private properties
    private var ref: FIRDatabaseReference!
    private var storageRef: FIRStorageReference!
    private var firebaseUsers: [(snapshot: FIRDataSnapshot, image: NSData)]! = []
    private var _refHandleAdded: FIRDatabaseHandle!
    private var _refHandleRemoved: FIRDatabaseHandle!
    
    
    // Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        ref = FIRDatabase.database().reference()
        storageRef = FIRStorage.storage().reference()
        addUnwindButton()
        if forFollowers || forFollowing {
            getUsersForUserId()
        } else {
            // for a post
            getUsersForPostId()
        }
    }
    
    private func getImageForUserID(id: String, withClosure closure: (data: NSData) -> Void) {
        // Download the small image
        storageRef.child("users").child(id + "_small.jpg").dataWithMaxSize(INT64_MAX) { (data, error) in
            if let error = error {
                print("Error downloading: \(error)")
                return
            }
            if data != nil {
                closure(data: data!)
            }
        }
    }
    
    private func indexForKey(key: String) -> Int {
        // if the key doesn't exist
        if key == "" {
            return -1
        }
        // normal behavior
        if firebaseUsers.count > 0 {
            for i in 0...firebaseUsers.count - 1 {
                if key == firebaseUsers[i].snapshot.key {
                    return i
                }
            }
        }
        // didn't find a match
        return -1
    }
    
    override func viewDidDisappear(animated: Bool) {
        if postId != nil {
            ref.child("posts/\(postId!)/ups").removeObserverWithHandle(_refHandleAdded)
            ref.child("posts/\(postId!)/ups").removeObserverWithHandle(_refHandleRemoved)
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // if there are posts
        if (firebaseUsers.count > 0)
        {
            tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            tableView.backgroundView   = nil;
        }
        else
        {
            let label = UILabel(frame: CGRect(x: 0, y: 0,
                width: tableView.bounds.size.width,
                height: tableView.bounds.size.height))
            
            label.text = "Anyone here?"
            label.numberOfLines = 0
            label.textColor = UIColor.blackColor()
            label.textAlignment = NSTextAlignment.Center
            tableView.backgroundView = label
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        }
        return firebaseUsers.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.UserCellName, forIndexPath: indexPath)
        
        if let userCell = cell as? UserTableViewCell {
            userCell.user = User(snapshot: firebaseUsers[indexPath.row].snapshot)
            userCell.ProfilePicture = UIImage(data: firebaseUsers[indexPath.row].image)
        }
        return cell
    }
    
    
    // Firebase Functions
    private func getUsersForPostId() {
        if postId != nil {
            // Look for added ups
            _refHandleAdded = ref.child("posts/\(postId!)/ups").observeEventType(.ChildAdded) { [weak weakSelf = self] (idSnapshot: FIRDataSnapshot) -> Void in
                if weakSelf != nil {
                    let userId = idSnapshot.key
                    // do no count the initial init up
                    if userId != "init" {
                        weakSelf!.ref.child("users").child(userId).observeSingleEventOfType(.Value) { (userSnapshot: FIRDataSnapshot) -> Void in
                            weakSelf!.firebaseUsers.append((userSnapshot, NSData()))
                            weakSelf!.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: weakSelf!.firebaseUsers.count-1, inSection: 0)], withRowAnimation: .Automatic)
                            
                            // download image and add it asynchronously
                            weakSelf?.getImageForUserID(userSnapshot.key) { (data) in
                                let snapIndex = NSIndexPath(forRow: weakSelf!.indexForKey(userSnapshot.key), inSection: 0)
                                
                                // verify if cell index is still the same after download time
                                if weakSelf?.firebaseUsers[snapIndex.row].snapshot.key == userSnapshot.key {
                                    // add image to the firebase post and reload row
                                    weakSelf?.firebaseUsers[snapIndex.row] = (userSnapshot, data)
                                    weakSelf?.tableView.reloadRowsAtIndexPaths([snapIndex], withRowAnimation: .Automatic)
                                }
                            }
                            
                        }
                    }
                }
            }
            // Look for removed ups
            _refHandleRemoved = ref.child("posts/\(postId!)/ups").observeEventType(.ChildRemoved) { [weak weakSelf = self] (idSnapshot: FIRDataSnapshot) -> Void in
                if weakSelf != nil {
                    let userId = idSnapshot.key
                    weakSelf!.ref.child("users").child(userId).observeSingleEventOfType(.Value) { (userSnapshot: FIRDataSnapshot) -> Void in
                        let snapIndex = NSIndexPath(forRow: weakSelf!.indexForKey(userSnapshot.key), inSection: 0)
                        if snapIndex.row >= 0 {
                            weakSelf!.firebaseUsers.removeAtIndex(snapIndex.row)
                            weakSelf!.tableView.deleteRowsAtIndexPaths([snapIndex], withRowAnimation: .Automatic)
                        }
                    }
                }
            }
        }
    }
    
    private func getUsersForUserId() {
        if userId != nil {
            
            var childString: String
            if forFollowers {
                childString = "followers"
            } else {
                childString = "following"
            }
            
            // Look for added followers or following
            _refHandleAdded = ref.child("users").child(userId!).child(childString).observeEventType(.ChildAdded) { [weak weakSelf = self] (idSnapshot: FIRDataSnapshot) -> Void in
                if weakSelf != nil {
                    let followUserId = idSnapshot.key
                    // do no count the initial init up
                    if followUserId != "init" {
                        weakSelf!.ref.child("users").child(followUserId).observeSingleEventOfType(.Value) { (userSnapshot: FIRDataSnapshot) -> Void in
                            weakSelf!.firebaseUsers.append((userSnapshot, NSData()))
                            weakSelf!.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: weakSelf!.firebaseUsers.count-1, inSection: 0)], withRowAnimation: .Automatic)
                            
                            // download image and add it asynchronously
                            weakSelf!.getImageForUserID(userSnapshot.key) { (data) in
                                let snapIndex = NSIndexPath(forRow: weakSelf!.indexForKey(userSnapshot.key), inSection: 0)
                                
                                // verify if cell index is still the same after download time
                                if weakSelf?.firebaseUsers[snapIndex.row].snapshot.key == userSnapshot.key {
                                    // add image to the firebase post and reload row
                                    weakSelf!.firebaseUsers[snapIndex.row] = (userSnapshot, data)
                                    weakSelf!.tableView.reloadRowsAtIndexPaths([snapIndex], withRowAnimation: .Automatic)
                                }
                            }
                            
                        }
                    }
                }
            }
            // Look for removed ups
            _refHandleRemoved = ref.child("users").child(userId!).child(childString).observeEventType(.ChildRemoved) { [weak weakSelf = self] (idSnapshot: FIRDataSnapshot) -> Void in
                if weakSelf != nil {
                    let followUserId = idSnapshot.key
                    weakSelf!.ref.child("users").child(followUserId).observeSingleEventOfType(.Value) { (userSnapshot: FIRDataSnapshot) -> Void in
                        let snapIndex = NSIndexPath(forRow: weakSelf!.indexForKey(userSnapshot.key), inSection: 0)
                        if snapIndex.row >= 0 {
                            weakSelf!.firebaseUsers.removeAtIndex(snapIndex.row)
                            weakSelf!.tableView.deleteRowsAtIndexPaths([snapIndex], withRowAnimation: .Automatic)
                        }
                    }
                }
            }
        }

    }
    
    
    // Prepare for Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.ShowUserSegue:
                if let vc = segue.destinationViewController as? UserViewController {
                    if let sendingCell = sender as? UserTableViewCell {
                        vc.user = sendingCell.user
                    }
                }
            default: break
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
        static let UserCellName = "User Cell"
        static let ShowUserSegue = "Show User"
        static let UnwindSegue = "Unwind To Map"
    }
}
