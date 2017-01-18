//
//  MenuTableViewController.swift
//  Now
//
//  Created by Florian Bienefelt on 7/13/16.
//  Copyright © 2016 Now. All rights reserved.
//

import UIKit
import SideMenu
import Firebase
import FirebaseAuth

class MenuTableViewController: UITableViewController {
    
    // Model
    var currentUser: User?
    
    // Private properties
    private var ref: FIRDatabaseReference!
    private var _refHandles: FIRDatabaseHandle!
    
    // Storyboard outlets and actions
    @IBOutlet weak var SignInOutCell: UITableViewCell!
    @IBOutlet weak var MyProfileCell: UITableViewCell!
    @IBOutlet weak var MyPostsCell: UITableViewCell!
    @IBOutlet weak var UppedPostsCell: UITableViewCell!
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {}
    
    // Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        SideMenuManager.menuFadeStatusBar = false
        ref = FIRDatabase.database().reference()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        clearCellTexts()
        getCurrentUserFromFirebase() { self.updateCellTexts() }
    }
    
    // Tableview Datasource
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Deselect row automatically
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        if selectedCell != nil {
            switch selectedCell!.reuseIdentifier! {
            case CellIdentifiers.MyProfile: myProfile()
            case CellIdentifiers.MyPosts: myPosts()
            case CellIdentifiers.UppedPosts: uppedPosts()
            case CellIdentifiers.SignInOut: signInOut()
            case CellIdentifiers.About: about()
            default: break
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // The first section requires log in
        if (indexPath.section == 0) {
            if let _ = FIRAuth.auth()?.currentUser {
                return tableView.rowHeight
            } else {
                // collapse rows
                return 0
            }
        }
        return tableView.rowHeight
    }
    
    // Static cell functions
    private func myProfile() {
        
    }
    
    private func myPosts() {
        
    }
    
    private func uppedPosts() {
        
        
    }
    
    private func signInOut() {
        
        if let _ = FIRAuth.auth()?.currentUser {
            // Sign Out
            do {
                try FIRAuth.auth()?.signOut()
                clearCellTexts()
                
            } catch let error {
                let alertcontroller = UIAlertController(title: "Sign Out Error", message: String(error), preferredStyle: .Alert)
                let defaultAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
                
                alertcontroller.addAction(defaultAction)
                self.presentViewController(alertcontroller, animated: true, completion: nil)
            }
        } else {
            // Sign In
            performSegueWithIdentifier(Storyboard.LoginSegue, sender: "Sign In Cell")
        }
        
        // So that the 3 first rows hide and appear properly
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    private func updateCellTexts() {
        // Switch sign in/out cell text
        if let _ = FIRAuth.auth()?.currentUser {
            SignInOutCell.textLabel?.text = "Sign Out"
            
            if currentUser != nil{
                MyProfileCell.detailTextLabel?.text = currentUser!.username ?? ""
                MyPostsCell.detailTextLabel?.text = String(currentUser!.postCount ?? 0)
                UppedPostsCell.detailTextLabel?.text = String(currentUser!.upCount ?? 0)
            }
        } else {
            SignInOutCell.textLabel?.text = "Sign In"
            MyProfileCell.detailTextLabel?.text = ""
            MyPostsCell.detailTextLabel?.text = ""
            UppedPostsCell.detailTextLabel?.text = ""
        }
        
    }
    
    private func clearCellTexts() {
        if let _ = FIRAuth.auth()?.currentUser {
            SignInOutCell.textLabel?.text = "Sign Out"
        } else {
            SignInOutCell.textLabel?.text = "Sign In"
            MyProfileCell.detailTextLabel?.text = ""
            MyPostsCell.detailTextLabel?.text = ""
            UppedPostsCell.detailTextLabel?.text = ""
        }
    }
    
    private func about() {
        
    }
    
    private func getCurrentUserFromFirebase(withClosure closure : () -> Void) {
        if let currentAuthUser = FIRAuth.auth()?.currentUser {
            ref.child("users").child(currentAuthUser.uid).observeSingleEventOfType(.Value) { (userSnapshot: FIRDataSnapshot) -> Void in
                let newCurrentUser = User(snapshot: userSnapshot)
                self.currentUser = newCurrentUser
                closure()
            }
        }
    }
    
    
    // Prepare for segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.MyPostsSegue:
                if let vc = segue.destinationViewController as? PostTableViewController {
                    vc.forSpecificUser = true
                    if currentUser != nil {
                        vc.userId = currentUser!.id!
                    }
                }
            case Storyboard.MyUppedPostsSegue:
                if let vc = segue.destinationViewController as? PostTableViewController {
                    vc.forUserUps = true
                    if currentUser != nil {
                        vc.userId = currentUser!.id!
                    }
                }
            case Storyboard.MyProfileSegue:
                if let vc = segue.destinationViewController as? MyProfileViewController {
                    if currentUser != nil {
                        vc.currentUser = currentUser!
                        vc.navigationItem.title = "Me"
                    } else {
                        vc.navigationItem.title = "Not me yet!"
                    }
                }
            case Storyboard.LoginSegue:
                if let vc = segue.destinationViewController as? SignInViewController {
                    if sender != nil {
                    if String(sender!) == "Sign In Cell" {
                        vc.fromSignInButton = true
                    }
                    }
                }
            default: break
            }
        }
    }
    
    
    // Identifiers for each cell
    private struct CellIdentifiers {
        static let MyProfile = "My Profile"
        static let MyPosts = "My Posts"
        static let UppedPosts = "Upped Posts"
        static let SignInOut = "Sign In Out"
        static let About = "About"
    }
    
    // Storyboard Constants
    private struct Storyboard {
        static let LoginSegue = "Log In"
        static let MyPostsSegue = "Show My Posts"
        static let MyUppedPostsSegue = "Show My Upped Posts"
        static let MyProfileSegue = "Show My Profile"
    }
    
}
