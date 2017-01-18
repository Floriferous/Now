//
//  SignInViewController.swift
//  Now
//
//  Created by Florian Bienefelt on 7/16/16.
//  Copyright © 2016 Now. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SignInViewController: UIViewController, UITextFieldDelegate {
    
    var fromSignInButton = false
    
    // Private Properties
    private var ref: FIRDatabaseReference!
    
    // Storyboard outlets and actions
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var GoodStuffLabel: UILabel!
    
    @IBAction func CancelButton(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func tappedScrollView(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    @IBAction func createAccountButton(sender: UIButton) {
        if self.emailField.text == nil || self.passwordField.text == nil || self.usernameField.text == nil {
            showErrorAlert("Oops", message: "Please enter something in every field!")
        } else {
            if self.usernameField.text?.characters.count >= 3 {
                FIRAuth.auth()?.createUserWithEmail(self.emailField.text!, password: self.passwordField.text!) { [weak weakSelf = self] (user, error) in
                    if error == nil {
                        weakSelf?.createUser(withId: user!.uid)
                        
                        // Account creation success
                        weakSelf?.emailField.text = ""
                        weakSelf?.passwordField.text = ""
                        weakSelf?.usernameField.text = ""
                        
                        weakSelf?.dismissViewControllerAnimated(true, completion: nil)
                    } else {
                        weakSelf?.showErrorAlert("Account Creation Error", message: error?.localizedDescription)
                    }
                }
            } else {
                showErrorAlert("Oops", message: "Your username must be at least 3 characters long, try adding one or two!")
            }
        }
    }
    
    @IBAction func logInButton(sender: UIButton) {
        if self.emailField.text == nil || self.passwordField.text == nil {
            showErrorAlert("Oops", message: "Please enter something in both fields!")
        } else {
            FIRAuth.auth()?.signInWithEmail(self.emailField.text!, password: self.passwordField.text!) { [weak weakSelf = self] (user, error) in
                if error == nil {
                    // Log in success
                    //let user = User(
                    weakSelf?.emailField.text = ""
                    weakSelf?.passwordField.text = ""
                    weakSelf?.usernameField.text = ""
                    
                    //store in userdefaults
                    
                    // Go back to what you were doing
                    weakSelf?.dismissViewControllerAnimated(true, completion: nil)
                    
                } else {
                    weakSelf?.showErrorAlert("Log In Error", message: error?.localizedDescription)
                }
            }
        }
    }
    
    // Viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        usernameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        
        if fromSignInButton {
            GoodStuffLabel.hidden = true
        }
    }
    
    
    // General functions
    private func showErrorAlert(title: String, message: String?) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
        
        alertcontroller.addAction(defaultAction)
        self.presentViewController(alertcontroller, animated: true, completion: nil)
    }
    
    private func createUser(withId id: String) {
        // Prepare data for the new post
        var data = [String: AnyObject]()
        
        // This information is already verified
        data[UserFields.username] = usernameField.text! as String
        data[UserFields.email] = emailField.text! as String
        data[UserFields.date] = [".sv": "timestamp"]
        data[UserFields.followers] = ["init": true]
        data[UserFields.following] = ["init": true]
        
        // push to firebase
        ref.child("users").child(id).setValue(data)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Storyboard constants
    private struct Storyboard {
        static let ShowMapSegue = "Show Map"
    }
}
