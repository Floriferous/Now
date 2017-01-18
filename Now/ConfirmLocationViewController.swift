//
//  ConfirmLocationViewController.swift
//  Now
//
//  Created by Florian Bienefelt on 7/13/16.
//  Copyright © 2016 Now. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps


class ConfirmLocationViewController: UIViewController, GMSMapViewDelegate {
    
    // Model
    var newPostPicture: UIImage?
    
    // Private properties
    private let locationManager = CLLocationManager()
    private let circleView = UIView()
    private var target: CLLocationCoordinate2D?
    
    // Storyboard outlets and actions
    @IBOutlet weak var MapView: GMSMapView!
    @IBAction func ConfirmLocation(sender: UIButton) {
        performSegueWithIdentifier(StoryBoard.AddDescriptionSegue, sender: sender)
    }
    
    // Viewcontroller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocation()
        MapView.delegate = self
        
        circleView.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.5)
        MapView.addSubview(circleView)
        MapView.bringSubviewToFront(circleView)
        circleView.translatesAutoresizingMaskIntoConstraints = false
        
        let heightConstraint = NSLayoutConstraint(item: circleView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 50)
        let widthConstraint = NSLayoutConstraint(item: circleView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 50)
        let centerXConstraint = NSLayoutConstraint(item: circleView, attribute: .CenterX, relatedBy: .Equal, toItem: MapView, attribute: .CenterX, multiplier: 1, constant: 0)
        let centerYConstraint = NSLayoutConstraint(item: circleView, attribute: .CenterY, relatedBy: .Equal, toItem: MapView, attribute: .CenterY, multiplier: 1, constant: 0)
        NSLayoutConstraint.activateConstraints([heightConstraint, widthConstraint, centerXConstraint, centerYConstraint])
        
        MapView.updateConstraints()
        UIView.animateWithDuration(1.0, animations: { [unowned self] in
            self.MapView.layoutIfNeeded()
            self.circleView.layer.cornerRadius = CGRectGetWidth(self.circleView.frame)/2
            self.circleView.clipsToBounds = true
            })
    }
    
    // Setup
    private func setLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    // General functions
    @objc func mapView(mapView: GMSMapView, didChangeCameraPosition position: GMSCameraPosition) {
        target = position.target    }
    
    // Prepare for segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            if identifier == StoryBoard.AddDescriptionSegue {
                if let vc = segue.destinationViewController as? AddDescriptionViewController {
                    if newPostPicture != nil {
                        vc.newPostPicture = newPostPicture!
                    }
                    vc.newPostLocation = target
                }
            }
        }
    }
    
    // Storyboard constants
    private struct StoryBoard {
        static let AddDescriptionSegue = "Add Description"
    }
}

// User location tracking
extension ConfirmLocationViewController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            manager.startUpdatingLocation()
            MapView.myLocationEnabled = true
            MapView.settings.myLocationButton = true
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            MapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 14, bearing: 0, viewingAngle: 0)
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        // Do something about this!
    }
}

