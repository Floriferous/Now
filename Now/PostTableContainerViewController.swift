//
//  PostTableContainerViewController.swift
//  Now
//
//  Created by Florian Bienefelt on 7/16/16.
//  Copyright © 2016 Now. All rights reserved.
//

import UIKit
import CoreLocation

class PostTableContainerViewController: UIViewController {
    
    // Model, to be passed to PostTableViewController
    var userLocation: CLLocation?
    
    // Storyboard outlets and actions
    @IBOutlet weak var MenuBarButton: UIBarButtonItem!
    @IBOutlet weak var AddPostButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var MapViewButton: UIButton!
    @IBAction func unwindToList(_ segue: UIStoryboardSegue) {}
    @IBAction func AddPostButton(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: Storyboard.CreatePostSegue, sender: sender)
    }
    
    // Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
    }
    
    // Setup
    func setupButtons() {
        MenuBarButton.setTitleTextAttributes([NSFontAttributeName: UIFont.fontAwesome(ofSize: 30)], for: .normal)
        MenuBarButton.title = String.fontAwesomeIcon(name: .bars)
        
        AddPostButtonOutlet.setTitleTextAttributes([NSFontAttributeName: UIFont.fontAwesome(ofSize: 30)], for: .normal)
        AddPostButtonOutlet.title = String.fontAwesomeIcon(name: .plus)
        
        MapViewButton.setTitle(String.fontAwesomeIcon(name: .globe), for: .normal)
        MapViewButton.layer.cornerRadius = 20.0
        MapViewButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
    }
    
    // General functions
    func doSegue(_ sender: AnyObject?) {
        performSegue(withIdentifier: Storyboard.UnwindSegue, sender: sender)
    }
    
    // Prepare for segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == Storyboard.ContainerViewSegue {
                if let vc = segue.destination as? PostTableViewController {
                    vc.userLocation = userLocation
                }
            }
        }
    }
    
    // Storyboard constants
    fileprivate struct Storyboard {
        static let ContainerViewSegue = "Show Container"
        static let UnwindSegue = "Unwind to Map"
        static let CreatePostSegue = "Create Post"
        static let MenuSegue = "Show Menu"
    }
}
