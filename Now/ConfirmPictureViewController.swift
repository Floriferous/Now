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
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if newPostPicture != nil {
            ImageView.image = newPostPicture!
        }
    }
    
    
    // Prepare for segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            if identifier == Storyboard.ConfirmLocationSegue {
                if let vc = segue.destinationViewController as? ConfirmLocationViewController {
                    if newPostPicture != nil {
                        vc.newPostPicture = newPostPicture!
                    }
                }
            }
        }
    }
    
    // Storyboard constants
    private struct Storyboard {
        static let ConfirmLocationSegue = "Confirm Location"
    }
}
