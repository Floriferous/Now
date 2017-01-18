//
//  ConfirmPictureViewController.swift
//  Now
//
//  Created by Florian Bienefelt on 7/13/16.
//  Copyright © 2016 Now. All rights reserved.
//

import UIKit

class ConfirmPictureViewController: UIViewController {
    
    // Model
    var newPostPicture: UIImage?
    
    // Storyboard outlets and actions
    @IBOutlet weak var ImageView: UIImageView!
    
    // Viewcontroller lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if newPostPicture != nil {
            ImageView.image = newPostPicture!
        }
    }
    
    
    // Prepare for segues
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
