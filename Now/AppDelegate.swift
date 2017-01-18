//
//  AppDelegate.swift
//  Now
//
//  Created by Pierre Starkov on 22/06/16.
//  Copyright © 2016 Now. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    override init() {
        super.init()
        
        // Firebase initialization
        FIRApp.configure()
        FIRDatabase.database().persistenceEnabled = true
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Google Maps
        GMSServices.provideAPIKey("AIzaSyDNmU1rHo5R5lmOQSB36WA5BVnaWNioFeg")
        
        // Navigation bar colors
        UINavigationBar.appearance().barTintColor = GlobalColors.alizarinRed
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        
        return true
    }
    
    deinit {
        
    }
    
    func applicationWillTerminate(application: UIApplication) {
        FIRDatabase.database().purgeOutstandingWrites()
        
        //FIRDatabase.database()
        //.persistenceEnabled = false
    }
}

