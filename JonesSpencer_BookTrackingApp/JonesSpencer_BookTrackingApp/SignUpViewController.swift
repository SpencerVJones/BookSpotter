//  SignUpViewController.swift
//  JonesSpencer_BookTrackingApp
//  Created by Spencer Jones on 6/4/24.

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseAnalytics

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    // Authentication Outlets
    @IBOutlet var emailField: UITextField!
    @IBOutlet var nameField: UITextField!
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setting delegates for text fields
        emailField.delegate = self
        nameField.delegate = self
        usernameField.delegate = self
        passwordField.delegate = self
        
        // Changing return key to "Next" for all text fields except final change to "Done"
        emailField.returnKeyType = .next
        nameField.returnKeyType = .next
        usernameField.returnKeyType = .next
        passwordField.returnKeyType = .done
    }
    
    // MARK: UITextFieldDelegate Methods
    // Dismiss the keyboard when Done key is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            nameField.becomeFirstResponder()
        }
        else if textField == nameField {
            usernameField.becomeFirstResponder()
        }
        else if textField == usernameField {
            passwordField.becomeFirstResponder()
        }
        else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: - Authentication
    func signUp(withEmail email: String, password: String, name: String, username: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.showAlert(message: error.localizedDescription)
                return
            }
            // Handle sign-up success
            self.showAlert(message: "Sign Up Successful!")
            guard let uid = authResult?.user.uid else { return }
            self.saveUserInfo(uid: uid, name: name, username: username, email: email)
        }
    }
    
    // Save user info to Database
    func saveUserInfo(uid: String, name: String, username: String, email: String) {
        let databaseRef = Database.database().reference()
        let userRef = databaseRef.child("users").child(uid)
        userRef.setValue(["name": name, "username": username, "email": email]) { error, _ in
            if let error = error {
                self.showAlert(message: "Failed to save user info: \(error.localizedDescription)")
                return
            }
        }
    }
    
    // MARK: - Storyboard Actions
    @IBAction func SignUpButtonTap(_ sender: UIButton) {
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty,
              let name = nameField.text, !name.isEmpty,
              let username = usernameField.text, !username.isEmpty else {
            showAlert(message: "Please fill in all fields.")
            return
        }
        signUp(withEmail: email, password: password, name: name, username: username)
    }
    
    // Helper function to show alerts
    func showAlert(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
