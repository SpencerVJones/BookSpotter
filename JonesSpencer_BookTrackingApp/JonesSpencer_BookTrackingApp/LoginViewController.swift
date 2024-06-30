//  LoginViewController.swift
//  JonesSpencer_BookTrackingApp
//  Created by Spencer Jones on 6/4/24.

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseAnalytics

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // Authentication Outlets
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do { try Auth.auth().signOut() } catch { }
        
        // Setting delegates for text fields
        emailField.delegate = self
        passwordField.delegate = self
        
        // Changing return key to "Next" for all text fields except final change to "Done"
        emailField.returnKeyType = .next
        passwordField.returnKeyType = .done
    }
    
    // MARK: UITextFieldDelegate Methods
    
    // Dismiss keyboard when Done key pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: - Authentication
    func signIn(withEmail email: String, password: String) {
        
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.showAlert(message: "Login failed: \(error.localizedDescription)")
                return
            }
            self.showAlert(message: "Login Successful!")
        }
    }
    
    // MARK: - Storyboard Actions
    @IBAction func LoginButtonTap(_ sender: UIButton) {
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showAlert(message: "Please enter both email and password.")
            return
        }
        
        // Check if user exists in authentication database before attempting login
        Auth.auth().fetchSignInMethods(forEmail: email) { [weak self] (methods, error) in
            guard let self = self else { return }
            
            if let error = error as NSError? {
                // Handle error fetching sign-in methods (e.g., network error)
                self.showAlert(message: "Failed to fetch sign-in methods: \(error.localizedDescription)")
                return
            }
            
            if let methods = methods, methods.isEmpty {
                // No sign-in methods found, user does not exist
                self.showAlert(message: "User does not exist. Please sign up first.")
            } else {
                // User exists, proceed with login
                self.signIn(withEmail: email, password: password)
            }
        }
    }
    
    
    // Helper function to show alerts
    func showAlert(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
