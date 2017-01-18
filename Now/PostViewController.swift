//
//  PostViewController.swift
//  Now
//
//  Created by Florian Bienefelt on 7/15/16.
//  Copyright © 2016 Now. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps
import Firebase
import FirebaseAuth

class PostViewController: UIViewController {
    
    // Model
    var post: Post?
    var user: User?
    var currentUser: User?
    var userLocation: CLLocation?
    var upCount = 0
    
    // Private properties
    fileprivate var ref: FIRDatabaseReference!
    fileprivate var storageRef: FIRStorageReference!
    fileprivate var _refHandleChanged: FIRDatabaseHandle!
    fileprivate let locationManager = CLLocationManager()
    
    // Storyboard outlets and actions
    @IBOutlet weak var ScrollView: UIScrollView!
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var UpButtonOutlet: UIButton!
    @IBOutlet weak var UpLabel: UILabel!
    @IBOutlet weak var UpCountOutlet: UIButton!
    @IBOutlet weak var PostImage: UIImageView!
    @IBOutlet weak var PostTitle: UILabel!
    @IBOutlet weak var PostDescription: UILabel!
    @IBOutlet weak var MapView: GMSMapView!
    @IBOutlet weak var DirectionsOutlet: UIButton!
    @IBOutlet weak var UserDateButtonOutlet: UIButton!
    @IBOutlet weak var DistanceLabel: UILabel!
    @IBAction func DirectionsButton(_ sender: UIButton) {
        if post != nil {
            if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
                UIApplication.shared.openURL(URL(string:
                    "comgooglemaps://?saddr=&daddr=\(post!.latitude!),\(post!.longitude!)&directionsmode=driving")!)
                
            } else {
                
                // Show error, and propose apple maps
                
            }
        }
    }
    
    @IBAction func UserDateButton(_ sender: UIButton) {
        // Verify if user is logged in
        if let _ = FIRAuth.auth()?.currentUser {
            performSegue(withIdentifier: Storyboard.ShowUserSegue, sender: self)
        } else {
            performSegue(withIdentifier: Storyboard.LoginSegue, sender: self)
            return
        }
    }
    
    @IBAction func UpCountButton(_ sender: UIButton) {
        // Verify if user is logged in
        if let _ = FIRAuth.auth()?.currentUser {
            performSegue(withIdentifier: Storyboard.ShowUsersSegue, sender: self)
        } else {
            performSegue(withIdentifier: Storyboard.LoginSegue, sender: self)
            return
        }
    }
    
    @IBAction func UpButton(_ sender: UIButton) {
        if let _ = FIRAuth.auth()?.currentUser {
            // up or downvote post
            getCurrentUserFromFirebase() { [weak weakSelf = self] in weakSelf?.checkIfUserLiked(true) }
        } else {
            performSegue(withIdentifier: Storyboard.LoginSegue, sender: self)
            return
        }
    }
    
    // Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        storageRef = FIRStorage.storage().reference()
        setOutlets()
        setLocation()
        addUnwindButton()
        //self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()] // is this needed?
        
        // Observe ups, and increase/decrease the count every time the function is called
        if post != nil {
            // observe changes
            _refHandleChanged = ref.child("posts").child(post!.id!).observe(.childChanged) { [weak weakSelf = self] (idSnapshot: FIRDataSnapshot) -> Void in
                // - 1 to avoid counting the initial upvote
                weakSelf?.UpCountOutlet.setTitle("+" + String(idSnapshot.childrenCount - 1), for: UIControlState())
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setLikeCount()
        
        // Initialize camera to the location of the post
        if post != nil {
            let postLocation = CLLocationCoordinate2D(latitude: post!.latitude!, longitude: post!.longitude!)
            MapView.camera = GMSCameraPosition(target: postLocation, zoom: 15, bearing: 0, viewingAngle: 0)
        }
    }
    
    deinit {
        if post != nil {
            ref.child("posts").child(post!.id!).removeObserver(withHandle: _refHandleChanged)
        }
    }
    
    // Setup
    fileprivate func setLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    fileprivate func setOutlets() {
        if post != nil {
            PostTitle.text = post!.title
            PostDescription.text = post!.description
            UpCountOutlet.setTitle(String("+" + String(post!.upCount! - 1)), for: UIControlState())
            DirectionsOutlet.layer.cornerRadius = UpCountOutlet.frame.height / 4
            setUpButton()
            setImage()
            if userLocation != nil {
                let postLocation = CLLocation(latitude: post!.latitude!, longitude: post!.longitude!)
                if postLocation.distance(from: userLocation!) < 1000 {
                    DistanceLabel.text = String(Int(round(postLocation.distance(from: userLocation!) / 10) * 10)) + "m away"
                } else if postLocation.distance(from: userLocation!) < 100000 {
                    DistanceLabel.text = String((round(postLocation.distance(from: userLocation!) / 100) * 100) / 1000) + "km away"
                } else {
                    DistanceLabel.text = String(Int((round(postLocation.distance(from: userLocation!) / 1000) * 1000) / 1000)) + "km away"
                }
            } else {
                DistanceLabel.text = ""
            }
            
            // set user date button
            getPostUser(){ [weak weakSelf = self] in
                
                if weakSelf != nil && weakSelf!.user!.username != nil {
                    let title = timeAgoSinceDate(
                        weakSelf!.post!.creationTime!,
                        numericDates: true)
                        + " by " + weakSelf!.user!.username!
                    
                    weakSelf!.UserDateButtonOutlet.setTitle(title, for: UIControlState())
                }
            }
            
            addPostMarker()
        } else {
            let alertcontroller = UIAlertController(title: "Oops", message: "This is not the post you're looking for!", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            
            alertcontroller.addAction(defaultAction)
            self.present(alertcontroller, animated: true, completion: nil)
        }
    }
    
    fileprivate func setImage() {
        ActivityIndicator.startAnimating()
        // Download the large image
        storageRef.child("posts").child(post!.id! + "_large.jpg").data(withMaxSize: INT64_MAX) { [weak weakSelf = self] (data, error) in
            if let error = error {
                print("Error downloading: \(error)")
                return
            }
            if data != nil {
                weakSelf?.PostImage.image = UIImage(data: data!)
                weakSelf?.ActivityIndicator.stopAnimating()
            }
        }
    }
    
    fileprivate func setUpButton() {
        UpButtonOutlet.layer.cornerRadius = UpCountOutlet.frame.height / 3
        
        let color = GlobalColors.alizarinRed.cgColor.components
        let tint_factor = CGFloat(0.15)
        let newR = (color?[0])! + (1 - (color?[0])!) * tint_factor / 255
        let newG = (color?[1])! + (1 - (color?[1])!) * tint_factor / 255
        let newB = (color?[2])! + (1 - (color?[2])!) * tint_factor / 255
        
        UpButtonOutlet.backgroundColor = UIColor(red: newR, green: newG, blue: newB, alpha: 1.0)
        
        if let _ = FIRAuth.auth()?.currentUser {
            // up or downvote post
            getCurrentUserFromFirebase() { [weak weakSelf = self] in weakSelf?.checkIfUserLiked(false) }
        }
    }
    
    fileprivate func setLikeCount() {
        UpCountOutlet.layer.cornerRadius = UpCountOutlet.frame.height / 3
        
        let color = GlobalColors.alizarinRed.cgColor.components
        let tint_factor = CGFloat(0.15)
        let newR = (color?[0])! + (1 - (color?[0])!) * tint_factor / 255
        let newG = (color?[1])! + (1 - (color?[1])!) * tint_factor / 255
        let newB = (color?[2])! + (1 - (color?[2])!) * tint_factor / 255
        
        UpCountOutlet.backgroundColor = UIColor(red: newR, green: newG, blue: newB, alpha: 1.0)
    }
    
    fileprivate func addPostMarker() {
        if post != nil {
            let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: post!.latitude!, longitude: post!.longitude!))
            marker.map = MapView
        }
    }
    
    // General functions
    fileprivate func checkIfUserLiked(_ buttonPressed: Bool) {
        if post != nil {
            if currentUser != nil {
                ref.child("posts/\(post!.id!)/ups").child(currentUser!.id!).observeSingleEvent(of: .value) { [weak weakSelf = self] (snapshot: FIRDataSnapshot) -> Void in
                    if snapshot.value is NSNull && weakSelf != nil {
                        // no up from this user yet, add one
                        if buttonPressed {
                            // update ups in Post
                            let userId = [weakSelf!.currentUser!.id!: true]
                            weakSelf?.ref.child("posts/\(self.post!.id!)/ups").updateChildValues(userId)
                            // update ups in current User
                            let postId = [weakSelf!.post!.id!: true]
                            weakSelf?.ref.child("users").child(self.currentUser!.id!).child("ups").updateChildValues(postId)
                            // update uplabel
                            weakSelf?.UpLabel.text = "⬆︎"
                        } else {
                            // if just checking, set current Up value to uplabel
                            weakSelf?.UpLabel.text = ""
                        }
                    } else if weakSelf != nil {
                        // up already exists -> remove it
                        if buttonPressed {
                            // remove up from post
                            weakSelf?.ref.child("posts/\(self.post!.id!)/ups").child(self.currentUser!.id!).removeValue()
                            // remove up from user
                            weakSelf?.ref.child("users").child(self.currentUser!.id!).child("ups").child(self.post!.id!).removeValue()
                            // update uplabel
                            weakSelf?.UpLabel.text = ""
                        } else {
                            // if just checking, set current Up value to uplabel
                            weakSelf?.UpLabel.text = "⬆︎"
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func getPostUser(withClosure closure: @escaping () -> Void) {
        if post != nil {
            ref.child("users").child(post!.userId!).observeSingleEvent(of: .value) { (userSnapshot: FIRDataSnapshot) -> Void in
                self.user = User(snapshot: userSnapshot)
                closure()
            }
        }
    }
    
    fileprivate func getCurrentUserFromFirebase(withClosure closure : @escaping () -> Void) {
        if let currentAuthUser = FIRAuth.auth()?.currentUser {
            ref.child("users").child(currentAuthUser.uid).observeSingleEvent(of: .value) { (userSnapshot: FIRDataSnapshot) -> Void in
                let newCurrentUser = User(snapshot: userSnapshot)
                self.currentUser = newCurrentUser
                closure()
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
    
    // Prepare for Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.ShowUsersSegue:
                if let vc = segue.destination as? UserTableViewController {
                    vc.navigationItem.title = "Ups"
                    vc.postId = post!.id
                }
            case Storyboard.ShowUserSegue:
                if let vc = segue.destination as? UserViewController {
                    vc.user = user
                }
            default: break
            }
        }
    }
    
    // Storyboard constants
    fileprivate struct Storyboard {
        static let ShowUsersSegue = "Show Users"
        static let ShowUserSegue = "Show User"
        static let LoginSegue = "Log In"
        static let UnwindSegue = "Unwind To Map"
    }
    
}



// User location tracking
extension PostViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            manager.startUpdatingLocation()
            MapView.isMyLocationEnabled = true
            MapView.settings.myLocationButton = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if post != nil {
            let postLocation = CLLocationCoordinate2D(latitude: post!.latitude!, longitude: post!.longitude!)
            if let userLocation = locations.first {
                let bounds = GMSCoordinateBounds.init(coordinate: userLocation.coordinate, coordinate: postLocation)
                MapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 50.0))
                manager.stopUpdatingLocation()
            } else {
                MapView.camera = GMSCameraPosition(target: postLocation, zoom: 14, bearing: 0, viewingAngle: 0)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Do something about this!
    }
}
