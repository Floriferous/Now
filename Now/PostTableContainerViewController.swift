//
//  PostTableContainerViewController.swift
//  Now
//
//  Created by Florian Bienefelt on 7/16/16.
//  Copyright © 2016 Now. All rights reserved.
//

import UIKit
import CoreLocation
import Fusuma

class PostTableContainerViewController: UIViewController {
    
    // Model, to be passed to PostTableViewController
    var userLocation: CLLocation?
    
    // Storyboard outlets and actions
    @IBOutlet weak var MenuBarButton: UIBarButtonItem!
    @IBOutlet weak var AddPostButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var MapViewButton: UIButton!
    @IBAction func unwindToList(segue: UIStoryboardSegue) {}
    @IBAction func AddPostButton(sender: UIBarButtonItem) {
        performSegueWithIdentifier(Storyboard.CreatePostSegue, sender: sender)
    }
    
    // Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
    }
    
    // Setup
    func setupButtons() {
        MenuBarButton.setTitleTextAttributes([NSFontAttributeName: UIFont.fontAwesomeOfSize(30)], forState: .Normal)
        MenuBarButton.title = String.fontAwesomeIconWithName(.Bars)
        
        AddPostButtonOutlet.setTitleTextAttributes([NSFontAttributeName: UIFont.fontAwesomeOfSize(30)], forState: .Normal)
        AddPostButtonOutlet.title = String.fontAwesomeIconWithName(.Plus)
        
        MapViewButton.setTitle(String.fontAwesomeIconWithName(.Globe), forState: .Normal)
        MapViewButton.layer.cornerRadius = 20.0
        MapViewButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Center
    }
    
    // General functions
    func doSegue(sender: AnyObject?) {
        performSegueWithIdentifier(Storyboard.UnwindSegue, sender: sender)
    }
    
    // Prepare for segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            if identifier == Storyboard.ContainerViewSegue {
                if let vc = segue.destinationViewController as? PostTableViewController {
                    vc.userLocation = userLocation
                }
            }
        }
    }
    
    // Storyboard constants
    private struct Storyboard {
        static let ContainerViewSegue = "Show Container"
        static let UnwindSegue = "Unwind to Map"
        static let CreatePostSegue = "Create Post"
        static let MenuSegue = "Show Menu"
    }
}
