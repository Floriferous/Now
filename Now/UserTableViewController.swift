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
    fileprivate var ref: FIRDatabaseReference!
    fileprivate var storageRef: FIRStorageReference!
    fileprivate var firebaseUsers: [(snapshot: FIRDataSnapshot, image: Data)]! = []
    fileprivate var _refHandleAdded: FIRDatabaseHandle!
    fileprivate var _refHandleRemoved: FIRDatabaseHandle!
    
    
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
    
    fileprivate func getImageForUserID(_ id: String, withClosure closure: @escaping (_ data: Data) -> Void) {
        // Download the small image
        storageRef.child("users").child(id + "_small.jpg").data(withMaxSize: INT64_MAX) { (data, error) in
            if let error = error {
                print("Error downloading: \(error)")
                return
            }
            if data != nil {
                closure(data!)
            }
        }
    }
    
    fileprivate func indexForKey(_ key: String) -> Int {
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
    
    override func viewDidDisappear(_ animated: Bool) {
        if postId != nil {
            ref.child("posts/\(postId!)/ups").removeObserver(withHandle: _refHandleAdded)
            ref.child("posts/\(postId!)/ups").removeObserver(withHandle: _refHandleRemoved)
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // if there are posts
        if (firebaseUsers.count > 0)
        {
            tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
            tableView.backgroundView   = nil;
        }
        else
        {
            let label = UILabel(frame: CGRect(x: 0, y: 0,
                width: tableView.bounds.size.width,
                height: tableView.bounds.size.height))
            
            label.text = "Anyone here?"
            label.numberOfLines = 0
            label.textColor = UIColor.black
            label.textAlignment = NSTextAlignment.center
            tableView.backgroundView = label
            tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        }
        return firebaseUsers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.UserCellName, for: indexPath)
        
        if let userCell = cell as? UserTableViewCell {
            userCell.user = User(snapshot: firebaseUsers[indexPath.row].snapshot)
            userCell.ProfilePicture = UIImage(data: firebaseUsers[indexPath.row].image)
        }
        return cell
    }
    
    
    // Firebase Functions
    fileprivate func getUsersForPostId() {
        if postId != nil {
            // Look for added ups
            _refHandleAdded = ref.child("posts/\(postId!)/ups").observe(.childAdded) { [weak weakSelf = self] (idSnapshot: FIRDataSnapshot) -> Void in
                if weakSelf != nil {
                    let userId = idSnapshot.key
                    // do no count the initial init up
                    if userId != "init" {
                        weakSelf!.ref.child("users").child(userId).observeSingleEvent(of: .value) { (userSnapshot: FIRDataSnapshot) -> Void in
                            weakSelf!.firebaseUsers.append((userSnapshot, Data()))
                            weakSelf!.tableView.insertRows(at: [IndexPath(row: weakSelf!.firebaseUsers.count-1, section: 0)], with: .automatic)
                            
                            // download image and add it asynchronously
                            weakSelf?.getImageForUserID(userSnapshot.key) { (data) in
                                let snapIndex = IndexPath(row: weakSelf!.indexForKey(userSnapshot.key), section: 0)
                                
                                // verify if cell index is still the same after download time
                                if weakSelf?.firebaseUsers[snapIndex.row].snapshot.key == userSnapshot.key {
                                    // add image to the firebase post and reload row
                                    weakSelf?.firebaseUsers[snapIndex.row] = (userSnapshot, data)
                                    weakSelf?.tableView.reloadRows(at: [snapIndex], with: .automatic)
                                }
                            }
                            
                        }
                    }
                }
            }
            // Look for removed ups
            _refHandleRemoved = ref.child("posts/\(postId!)/ups").observe(.childRemoved) { [weak weakSelf = self] (idSnapshot: FIRDataSnapshot) -> Void in
                if weakSelf != nil {
                    let userId = idSnapshot.key
                    weakSelf!.ref.child("users").child(userId).observeSingleEvent(of: .value) { (userSnapshot: FIRDataSnapshot) -> Void in
                        let snapIndex = IndexPath(row: weakSelf!.indexForKey(userSnapshot.key), section: 0)
                        if snapIndex.row >= 0 {
                            weakSelf!.firebaseUsers.remove(at: snapIndex.row)
                            weakSelf!.tableView.deleteRows(at: [snapIndex], with: .automatic)
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func getUsersForUserId() {
        if userId != nil {
            
            var childString: String
            if forFollowers {
                childString = "followers"
            } else {
                childString = "following"
            }
            
            // Look for added followers or following
            _refHandleAdded = ref.child("users").child(userId!).child(childString).observe(.childAdded) { [weak weakSelf = self] (idSnapshot: FIRDataSnapshot) -> Void in
                if weakSelf != nil {
                    let followUserId = idSnapshot.key
                    // do no count the initial init up
                    if followUserId != "init" {
                        weakSelf!.ref.child("users").child(followUserId).observeSingleEvent(of: .value) { (userSnapshot: FIRDataSnapshot) -> Void in
                            weakSelf!.firebaseUsers.append((userSnapshot, Data()))
                            weakSelf!.tableView.insertRows(at: [IndexPath(row: weakSelf!.firebaseUsers.count-1, section: 0)], with: .automatic)
                            
                            // download image and add it asynchronously
                            weakSelf!.getImageForUserID(userSnapshot.key) { (data) in
                                let snapIndex = IndexPath(row: weakSelf!.indexForKey(userSnapshot.key), section: 0)
                                
                                // verify if cell index is still the same after download time
                                if weakSelf?.firebaseUsers[snapIndex.row].snapshot.key == userSnapshot.key {
                                    // add image to the firebase post and reload row
                                    weakSelf!.firebaseUsers[snapIndex.row] = (userSnapshot, data)
                                    weakSelf!.tableView.reloadRows(at: [snapIndex], with: .automatic)
                                }
                            }
                            
                        }
                    }
                }
            }
            // Look for removed ups
            _refHandleRemoved = ref.child("users").child(userId!).child(childString).observe(.childRemoved) { [weak weakSelf = self] (idSnapshot: FIRDataSnapshot) -> Void in
                if weakSelf != nil {
                    let followUserId = idSnapshot.key
                    weakSelf!.ref.child("users").child(followUserId).observeSingleEvent(of: .value) { (userSnapshot: FIRDataSnapshot) -> Void in
                        let snapIndex = IndexPath(row: weakSelf!.indexForKey(userSnapshot.key), section: 0)
                        if snapIndex.row >= 0 {
                            weakSelf!.firebaseUsers.remove(at: snapIndex.row)
                            weakSelf!.tableView.deleteRows(at: [snapIndex], with: .automatic)
                        }
                    }
                }
            }
        }

    }
    
    
    // Prepare for Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.ShowUserSegue:
                if let vc = segue.destination as? UserViewController {
                    if let sendingCell = sender as? UserTableViewCell {
                        vc.user = sendingCell.user
                    }
                }
            default: break
            }
        }
    }
    
    
    // The unwind button and its unwind action
    fileprivate func addUnwindButton() {
        // Disable unwind button if this VC is early in the stack
        if self.navigationController?.viewControllers.count == 1 {
            self.navigationItem.rightBarButtonItem = nil
        } else {
            let unwindButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(unwind(_:)))
            unwindButton.setTitleTextAttributes([NSFontAttributeName: UIFont.fontAwesome(ofSize: 30)], for: .normal)
            unwindButton.title = String.fontAwesomeIcon(name: .times)
            self.navigationItem.rightBarButtonItem = unwindButton
        }
    }
    @objc fileprivate func unwind(_ sender: AnyObject?) {
        performSegue(withIdentifier: Storyboard.UnwindSegue, sender: nil)
    }
    
    // Storyboard constants
    fileprivate struct Storyboard {
        static let UserCellName = "User Cell"
        static let ShowUserSegue = "Show User"
        static let UnwindSegue = "Unwind To Map"
    }
}
