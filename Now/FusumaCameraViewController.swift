//
//  FusumaCameraViewController.swift
//  Now
//
//  Created by Florian Bienefelt on 7/22/16.
//  Copyright © 2016 Florian Bienefelt. All rights reserved.
//

import UIKit
import Fusuma

class FusumaCameraViewController: UIViewController, FusumaDelegate {
    
    var newPostPicture: UIImage?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController!.setNavigationBarHidden(true, animated: false)
        
        let fusuma = FusumaViewController()
        fusuma.modeOrder = FusumaModeOrder.CameraFirst
        fusumaCropImage = true
        fusuma.delegate = self
        
        presentViewController(fusuma, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController!.setNavigationBarHidden(false, animated: animated)

    }
    
    // Fusuma Camera functions
    // Return the image which is selected from camera roll or is taken via the camera.
    func fusumaImageSelected(_ image: UIImage) {
        newPostPicture = image
        performSegue(withIdentifier: Storyboard.ConfirmLocationSegue, sender: nil)
    }
    
    // Return the image but called after is dismissed.
    func fusumaDismissedWithImage(_ image: UIImage) {
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: URL) {
        print("Called just after a video has been selected.")
    }
    
    // When camera roll is not authorized, this method is called.
    func fusumaCameraRollUnauthorized() {
        print("Camera roll unauthorized")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == Storyboard.ConfirmLocationSegue {
                if let vc = segue.destination as? ConfirmLocationViewController {
                    if newPostPicture != nil {
                        vc.newPostPicture = newPostPicture!
                    }
                }
            }
        }
    }
    
    
    // Storyboard constants
    fileprivate struct Storyboard {
        static let ConfirmLocationSegue = "Confirm Location"
    }
}

