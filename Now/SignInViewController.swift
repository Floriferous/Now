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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class SignInViewController: UIViewController, UITextFieldDelegate {
    
    var fromSignInButton = false
    
    // Private Properties
    fileprivate var ref: FIRDatabaseReference!
    
    // Storyboard outlets and actions
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var GoodStuffLabel: UILabel!
    
    @IBAction func CancelButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tappedScrollView(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    @IBAction func createAccountButton(_ sender: UIButton) {
        if self.emailField.text == nil || self.passwordField.text == nil || self.usernameField.text == nil {
            showErrorAlert("Oops", message: "Please enter something in every field!")
        } else {
            if self.usernameField.text?.characters.count >= 3 {
                FIRAuth.auth()?.createUser(withEmail: self.emailField.text!, password: self.passwordField.text!) { [weak weakSelf = self] (user, error) in
                    if error == nil {
                        weakSelf?.createUser(withId: user!.uid)
                        
                        // Account creation success
                        weakSelf?.emailField.text = ""
                        weakSelf?.passwordField.text = ""
                        weakSelf?.usernameField.text = ""
                        
                        weakSelf?.dismiss(animated: true, completion: nil)
                    } else {
                        weakSelf?.showErrorAlert("Account Creation Error", message: error?.localizedDescription)
                    }
                }
            } else {
                showErrorAlert("Oops", message: "Your username must be at least 3 characters long, try adding one or two!")
            }
        }
    }
    
    @IBAction func logInButton(_ sender: UIButton) {
        if self.emailField.text == nil || self.passwordField.text == nil {
            showErrorAlert("Oops", message: "Please enter something in both fields!")
        } else {
            FIRAuth.auth()?.signIn(withEmail: self.emailField.text!, password: self.passwordField.text!) { [weak weakSelf = self] (user, error) in
                if error == nil {
                    // Log in success
                    //let user = User(
                    weakSelf?.emailField.text = ""
                    weakSelf?.passwordField.text = ""
                    weakSelf?.usernameField.text = ""
                    
                    //store in userdefaults
                    
                    // Go back to what you were doing
                    weakSelf?.dismiss(animated: true, completion: nil)
                    
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
            GoodStuffLabel.isHidden = true
        }
    }
    
    
    // General functions
    fileprivate func showErrorAlert(_ title: String, message: String?) {
        let alertcontroller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        
        alertcontroller.addAction(defaultAction)
        self.present(alertcontroller, animated: true, completion: nil)
    }
    
    fileprivate func createUser(withId id: String) {
        // Prepare data for the new post
        var data = [String: AnyObject]()
        
        // This information is already verified
        data[UserFields.username] = usernameField.text! as String as AnyObject?
        data[UserFields.email] = emailField.text! as String as AnyObject?
        data[UserFields.date] = [".sv": "timestamp"]
        data[UserFields.followers] = ["init": true]
        data[UserFields.following] = ["init": true]
        
        // push to firebase
        ref.child("users").child(id).setValue(data)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Storyboard constants
    fileprivate struct Storyboard {
        static let ShowMapSegue = "Show Map"
    }
}
