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
    fileprivate let locationManager = CLLocationManager()
    fileprivate var ref: FIRDatabaseReference!
    fileprivate var storageRef: FIRStorageReference!
    fileprivate var newPostPictureData: Data?
    
    fileprivate var _refHandleAdded: FIRDatabaseHandle!
    fileprivate var _refHandleRemoved: FIRDatabaseHandle!
    
    // Storyboard outlets and actions
    @IBOutlet weak var MapView: GMSMapView!
    @IBOutlet weak var AddPostButtonOutlet: UIButton! { didSet {
        AddPostButtonOutlet.setTitle(String.fontAwesomeIconWithName(.Plus), for: .Normal)
        AddPostButtonOutlet.layer.cornerRadius = 20.0
        addButtonShadow(AddPostButtonOutlet)} }
    @IBOutlet weak var ListViewButtonOutlet: UIButton! { didSet {
        ListViewButtonOutlet.setTitle(String.fontAwesomeIconWithName(.ThList), for: .Normal)
        ListViewButtonOutlet.layer.cornerRadius = 20.0
        addButtonShadow(ListViewButtonOutlet)} }
    @IBOutlet weak var MenuButtonOutlet: UIButton! { didSet {
        MenuButtonOutlet.setTitle(String.fontAwesomeIconWithName(.Bars), for: .Normal)
        MenuButtonOutlet.layer.cornerRadius = 20.0
        addButtonShadow(MenuButtonOutlet)} }
    @IBAction func unwindToMap(_ segue: UIStoryboardSegue) {}
    
    @IBAction func AddPostButton(_ sender: UIButton) {
        performSegue(withIdentifier: Storyboard.CreatePostSegue, sender: sender)
    }
    
    // Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocation()
        ref = FIRDatabase.database().reference()
        storageRef = FIRStorage.storage().reference()
        MapView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Look for new posts
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        _refHandleAdded = ref.child("posts").observe(.childAdded) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
            weakSelf?.firebasePosts.append(snapshot)
            weakSelf?.setMarkers()
        }
        // Look for removed posts
        _refHandleRemoved = ref.child("posts").observe(.childRemoved) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
            if weakSelf != nil {
                let snapIndex = weakSelf!.indexForKey(snapshot.key)
                if snapIndex >= 0 {
                    weakSelf!.firebasePosts.remove(at: snapIndex)
                    weakSelf!.setMarkers(true)
                }
            }
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
                if key == firebasePosts[i].key {
                    return i
                }
            }
        }
        // didn't find a match
        return -1
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if newPost != nil {
            // if there is a new post, set target at post and animate new post on map
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ref.child("posts").removeObserver(withHandle: _refHandleAdded)
        ref.child("posts").removeObserver(withHandle: _refHandleRemoved)
    }
    
    // Setup
    fileprivate func addButtonShadow(_ button: UIButton) {
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.4
        button.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        button.layer.shadowRadius = 0.5
        // cache shadows for faster performance
        button.layer.shouldRasterize = true
    }
    
    fileprivate func setLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 100
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    fileprivate func setMarkers(_ removing: Bool = false) {
        if removing {
            MapView.clear()
        }
        
        var posts = [Post]()
        if firebasePosts.count > 0 {
            for i in 0...firebasePosts.count - 1 {
                posts.insert(Post(snapshot: firebasePosts[i]), at: 0)
                let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: posts[0].latitude!, longitude: posts[0].longitude!))
                marker.title = posts[0].title
                marker.userData = posts[0]
                marker.map = MapView
            }
        }
    }
    
    // Prevent map from moving when you tap on a marker
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        MapView.selectedMarker = marker
        return true
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        performSegue(withIdentifier: Storyboard.ShowPostSegue, sender: marker)
    }
    
    // Prepare for segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.ListViewSegue:
                if let navcon = segue.destination as? UINavigationController {
                    if let vc = navcon.visibleViewController as? PostTableContainerViewController {
                        vc.userLocation = MapView.myLocation
                    }
                }
            case Storyboard.ShowPostSegue:
                if let vc = segue.destination as? PostViewController {
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
    fileprivate struct Storyboard {
        static let ListViewSegue = "Show List"
        static let CreatePostSegue = "Create Post"
        static let MenuSegue = "Show Menu"
        static let ShowPostSegue = "Show Post"
    }
}




// User location tracking
extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            manager.startUpdatingLocation()
            if MapView != nil {
                MapView.isMyLocationEnabled = true
                MapView.settings.myLocationButton = true
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            if MapView != nil {
                MapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 14, bearing: 0, viewingAngle: 0)
            }
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Do something about this!
    }
}

