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
    fileprivate let captureSession = AVCaptureSession()
    fileprivate let stillImageOutput = AVCaptureStillImageOutput()
    
    // Storyboard outlets and actions
    @IBOutlet var CameraView: UIImageView!
    
    @IBAction func TakePicture(_ sender: UIButton) {
        if let videoConnection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection) {
                [weak weakSelf = self] (imageDataSampleBuffer, error) -> Void in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                weakSelf?.newPostPicture = UIImage(data: imageData!)
                weakSelf?.performSegue(withIdentifier: Storyboard.ConfirmPictureSegue, sender: sender)
            }
        }
    }
    
    // Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // Setup
    fileprivate func setupCamera() {
        let devices = AVCaptureDevice.devices().filter{ ($0 as AnyObject).hasMediaType(AVMediaTypeVideo) && ($0 as AnyObject).position == AVCaptureDevicePosition.back }
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
                    previewLayer.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.width)
                    previewLayer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
                    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                    CameraView.layer.addSublayer(previewLayer)
                }
            } catch {
                print("Error in image SecondViewController")
            }
        }
    }

    // Prepare for segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if newPostPicture != nil {
            if let identifier = segue.identifier {
                if identifier == Storyboard.ConfirmPictureSegue {
                    if let vc = segue.destination as? ConfirmPictureViewController {
                        vc.newPostPicture = newPostPicture
                    }
                }
            }
        }
    }

    
    
    
    
    
    // Storyboard constants
    fileprivate struct Storyboard {
        static let ConfirmPictureSegue = "Confirm Picture"
    }
}

