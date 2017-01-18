//
//  FirstViewController.swift
//  Now
//
//  Created by Pierre Starkov on 22/06/16.
//  Copyright © 2016 Now. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps
import Firebase

class MapViewController: UIViewController, GMSMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Model
    var firebasePosts: [FIRDataSnapshot]! = []
    var newPost: Post?
    
    // Private properties
    private let locationManager = CLLocationManager()
    private var ref: FIRDatabaseReference!
    private var storageRef: FIRStorageReference!
    private var newPostPictureData: NSData?
    
    private var _refHandleAdded: FIRDatabaseHandle!
    private var _refHandleRemoved: FIRDatabaseHandle!
    
    // Storyboard outlets and actions
    @IBOutlet weak var MapView: GMSMapView!
    @IBOutlet weak var AddPostButtonOutlet: UIButton! { didSet {
        AddPostButtonOutlet.setTitle(String.fontAwesomeIconWithName(.Plus), forState: .Normal)
        AddPostButtonOutlet.layer.cornerRadius = 20.0
        addButtonShadow(AddPostButtonOutlet)} }
    @IBOutlet weak var ListViewButtonOutlet: UIButton! { didSet {
        ListViewButtonOutlet.setTitle(String.fontAwesomeIconWithName(.ThList), forState: .Normal)
        ListViewButtonOutlet.layer.cornerRadius = 20.0
        addButtonShadow(ListViewButtonOutlet)} }
    @IBOutlet weak var MenuButtonOutlet: UIButton! { didSet {
        MenuButtonOutlet.setTitle(String.fontAwesomeIconWithName(.Bars), forState: .Normal)
        MenuButtonOutlet.layer.cornerRadius = 20.0
        addButtonShadow(MenuButtonOutlet)} }
    @IBAction func unwindToMap(segue: UIStoryboardSegue) {}
    
    @IBAction func AddPostButton(sender: UIButton) {
        performSegueWithIdentifier(Storyboard.CreatePostSegue, sender: sender)
    }
    
    // Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocation()
        ref = FIRDatabase.database().reference()
        storageRef = FIRStorage.storage().reference()
        MapView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Look for new posts
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        _refHandleAdded = ref.child("posts").observeEventType(.ChildAdded) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
            weakSelf?.firebasePosts.append(snapshot)
            weakSelf?.setMarkers()
        }
        // Look for removed posts
        _refHandleRemoved = ref.child("posts").observeEventType(.ChildRemoved) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
            if weakSelf != nil {
                let snapIndex = weakSelf!.indexForKey(snapshot.key)
                if snapIndex >= 0 {
                    weakSelf!.firebasePosts.removeAtIndex(snapIndex)
                    weakSelf!.setMarkers(true)
                }
            }
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
                if key == firebasePosts[i].key {
                    return i
                }
            }
        }
        // didn't find a match
        return -1
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if newPost != nil {
            // if there is a new post, set target at post and animate new post on map
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        ref.child("posts").removeObserverWithHandle(_refHandleAdded)
        ref.child("posts").removeObserverWithHandle(_refHandleRemoved)
    }
    
    // Setup
    private func addButtonShadow(button: UIButton) {
        button.layer.shadowColor = UIColor.blackColor().CGColor
        button.layer.shadowOpacity = 0.4
        button.layer.shadowOffset = CGSizeMake(0.0, 2.0)
        button.layer.shadowRadius = 0.5
        // cache shadows for faster performance
        button.layer.shouldRasterize = true
    }
    
    private func setLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 100
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    private func setMarkers(removing: Bool = false) {
        if removing {
            MapView.clear()
        }
        
        var posts = [Post]()
        if firebasePosts.count > 0 {
            for i in 0...firebasePosts.count - 1 {
                posts.insert(Post(snapshot: firebasePosts[i]), atIndex: 0)
                let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: posts[0].latitude!, longitude: posts[0].longitude!))
                marker.title = posts[0].title
                marker.userData = posts[0]
                marker.map = MapView
            }
        }
    }
    
    // Prevent map from moving when you tap on a marker
    func mapView(mapView: GMSMapView, didTapMarker marker: GMSMarker) -> Bool {
        MapView.selectedMarker = marker
        return true
    }
    
    func mapView(mapView: GMSMapView, didTapInfoWindowOfMarker marker: GMSMarker) {
        performSegueWithIdentifier(Storyboard.ShowPostSegue, sender: marker)
    }
    
    // Prepare for segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.ListViewSegue:
                if let navcon = segue.destinationViewController as? UINavigationController {
                    if let vc = navcon.visibleViewController as? PostTableContainerViewController {
                        vc.userLocation = MapView.myLocation
                    }
                }
            case Storyboard.ShowPostSegue:
                if let vc = segue.destinationViewController as? PostViewController {
                    if let marker = sender as? GMSMarker {
                        if let post = marker.userData as? Post {
                            vc.post = post
                            vc.userLocation = MapView.myLocation
                        }
                    }
                }
            default: break
            }
        }
    }
    
    // Storyboard constants
    private struct Storyboard {
        static let ListViewSegue = "Show List"
        static let CreatePostSegue = "Create Post"
        static let MenuSegue = "Show Menu"
        static let ShowPostSegue = "Show Post"
    }
}




// User location tracking
extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            manager.startUpdatingLocation()
            if MapView != nil {
                MapView.myLocationEnabled = true
                MapView.settings.myLocationButton = true
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            if MapView != nil {
                MapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 14, bearing: 0, viewingAngle: 0)
            }
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        // Do something about this!
    }
}

