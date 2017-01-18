//
//  SecondViewController.swift
//  Now
//
//  Created by Pierre Starkov on 22/06/16.
//  Copyright © 2016 Now. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    // Model
    var newPostPicture: UIImage?
    
    // Private properties
    private let captureSession = AVCaptureSession()
    private let stillImageOutput = AVCaptureStillImageOutput()
    
    // Storyboard outlets and actions
    @IBOutlet var CameraView: UIImageView!
    
    @IBAction func TakePicture(sender: UIButton) {
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                [weak weakSelf = self] (imageDataSampleBuffer, error) -> Void in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                weakSelf?.newPostPicture = UIImage(data: imageData)
                weakSelf?.performSegueWithIdentifier(Storyboard.ConfirmPictureSegue, sender: sender)
            }
        }
    }
    
    // Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCamera()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // Setup
    private func setupCamera() {
        let devices = AVCaptureDevice.devices().filter{ $0.hasMediaType(AVMediaTypeVideo) && $0.position == AVCaptureDevicePosition.Back }
        if let captureDevice = devices.first as? AVCaptureDevice  {
            do {
                try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
                captureSession.sessionPreset = AVCaptureSessionPresetPhoto
                captureSession.startRunning()
                stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
                if captureSession.canAddOutput(stillImageOutput) {
                    captureSession.addOutput(stillImageOutput)
                }
                if let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) {
                    previewLayer.bounds = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.width)
                    previewLayer.position = CGPointMake(self.view.bounds.midX, self.view.bounds.midY)
                    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                    CameraView.layer.addSublayer(previewLayer)
                }
            } catch {
                print("Error in image SecondViewController")
            }
        }
    }

    // Prepare for segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if newPostPicture != nil {
            if let identifier = segue.identifier {
                if identifier == Storyboard.ConfirmPictureSegue {
                    if let vc = segue.destinationViewController as? ConfirmPictureViewController {
                        vc.newPostPicture = newPostPicture
                    }
                }
            }
        }
    }

    
    
    
    
    
    // Storyboard constants
    private struct Storyboard {
        static let ConfirmPictureSegue = "Confirm Picture"
    }
}

