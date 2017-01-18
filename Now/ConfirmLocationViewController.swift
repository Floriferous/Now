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
    fileprivate let locationManager = CLLocationManager()
    fileprivate let circleView = UIView()
    fileprivate var target: CLLocationCoordinate2D?
    
    // Storyboard outlets and actions
    @IBOutlet weak var MapView: GMSMapView!
    @IBAction func ConfirmLocation(_ sender: UIButton) {
        performSegue(withIdentifier: StoryBoard.AddDescriptionSegue, sender: sender)
    }
    
    // Viewcontroller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocation()
        MapView.delegate = self
        
        circleView.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        MapView.addSubview(circleView)
        MapView.bringSubview(toFront: circleView)
        circleView.translatesAutoresizingMaskIntoConstraints = false
        
        let heightConstraint = NSLayoutConstraint(item: circleView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50)
        let widthConstraint = NSLayoutConstraint(item: circleView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50)
        let centerXConstraint = NSLayoutConstraint(item: circleView, attribute: .centerX, relatedBy: .equal, toItem: MapView, attribute: .centerX, multiplier: 1, constant: 0)
        let centerYConstraint = NSLayoutConstraint(item: circleView, attribute: .centerY, relatedBy: .equal, toItem: MapView, attribute: .centerY, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([heightConstraint, widthConstraint, centerXConstraint, centerYConstraint])
        
        MapView.updateConstraints()
        UIView.animate(withDuration: 1.0, animations: { [unowned self] in
            self.MapView.layoutIfNeeded()
            self.circleView.layer.cornerRadius = self.circleView.frame.width/2
            self.circleView.clipsToBounds = true
            })
    }
    
    // Setup
    fileprivate func setLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    // General functions
    @objc func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        target = position.target    }
    
    // Prepare for segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == StoryBoard.AddDescriptionSegue {
                if let vc = segue.destination as? AddDescriptionViewController {
                    if newPostPicture != nil {
                        vc.newPostPicture = newPostPicture!
                    }
                    vc.newPostLocation = target
                }
            }
        }
    }
    
    // Storyboard constants
    fileprivate struct StoryBoard {
        static let AddDescriptionSegue = "Add Description"
    }
}

// User location tracking
extension ConfirmLocationViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            manager.startUpdatingLocation()
            MapView.isMyLocationEnabled = true
            MapView.settings.myLocationButton = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            MapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 14, bearing: 0, viewingAngle: 0)
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Do something about this!
    }
}

