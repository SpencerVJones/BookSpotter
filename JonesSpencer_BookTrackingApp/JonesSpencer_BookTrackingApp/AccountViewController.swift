//  AccountViewController.swift
//  JonesSpencer_BookTrackingApp
//  Created by Spencer Jones on 6/4/24.

import UIKit
import SDWebImage
import Firebase
import FirebaseStorage

class AccountViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // Profile outlets
    @IBOutlet var emailField: UITextField!
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var firstNameField: UITextField!
    @IBOutlet var lastNameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var profileImageView: UIImageView!
    
    var currentUser: User? {
        return Auth.auth().currentUser
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Account"
        
        emailField.isUserInteractionEnabled = false
        usernameField.isUserInteractionEnabled = false
        firstNameField.isUserInteractionEnabled = false
        lastNameField.isUserInteractionEnabled = false
        passwordField.isUserInteractionEnabled = false
        
        // Setting delegates for text fields
        emailField.delegate = self
        usernameField.delegate = self
        firstNameField.delegate = self
        lastNameField.delegate = self
        passwordField.delegate = self
        
        // Changing return key to "Next" for all text fields except final change to "Done"
        emailField.returnKeyType = .next
        usernameField.returnKeyType = .next
        firstNameField.returnKeyType = .next
        lastNameField.returnKeyType = .next
        passwordField.returnKeyType = .done
        
        fetchUserData()
    }
    
    // MARK: UITextFieldDelegate Methods
    // Dismiss keyboard when Done key is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            usernameField.becomeFirstResponder()
        }
        if textField == usernameField {
            firstNameField.becomeFirstResponder()
        }
        if textField == firstNameField {
            lastNameField.becomeFirstResponder()
        }
        if textField == lastNameField {
            passwordField.becomeFirstResponder()
        }
        else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    
    // MARK: Storyboard Actions
    @IBAction func editImageButtonTap(_ sender: UIButton) {
        // Will allow user to change image
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func editButtonTap(_ sender: UIButton) {
        // Will allow user to change text fields
        emailField.isUserInteractionEnabled = true
        usernameField.isUserInteractionEnabled = true
        firstNameField.isUserInteractionEnabled = true
        lastNameField.isUserInteractionEnabled = true
        passwordField.isUserInteractionEnabled = true
    }
    
    @IBAction func saveButtonTap(_ sender: Any) {
        // Will save the changes and update firebase database initally created from user login
        saveChanges()
    }
    
    private func saveChanges() {
        guard let user = currentUser else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        userRef.updateData([
            "email": emailField.text ?? "",
            "username": usernameField.text ?? "",
            "firstName": firstNameField.text ?? "",
            "lastName": lastNameField.text ?? ""
        ]) { error in
            if let error = error {
                print("Error updating user: \(error)")
            } else {
                print("User updated successfully")
            }
        }
        
    }
    
    // MARK: Fetch User Data
    func fetchUserData() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(user.uid)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                self.emailField.text = data?["email"] as? String
                self.usernameField.text = data?["username"] as? String
                self.firstNameField.text = data?["firstName"] as? String
                self.lastNameField.text = data?["lastName"] as? String
                
                if let profileImageURL = data?["profileImageURL"] as? String {
                    self.profileImageView.sd_setImage(with: URL(string: profileImageURL), placeholderImage: UIImage(named: "defaultProfileImage"))
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    // MARK: Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            profileImageView.image = selectedImage
            // Save to Firebase Storage
            saveProfileImage(image: selectedImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Save Profile Image
    func saveProfileImage(image: UIImage) {
        guard let user = Auth.auth().currentUser else { return }
        let storageRef = Storage.storage().reference().child("profileImages").child("\(user.uid).jpg")
        
        if let imageData = image.jpegData(compressionQuality: 0.75) {
            storageRef.putData(imageData, metadata: nil) { (metadata, error) in
                if let error = error {
                    print("Error uploading image: \(error)")
                    return
                }
                storageRef.downloadURL { (url, error) in
                    if let error = error {
                        print("Error getting download URL: \(error)")
                        return
                    }
                    if let profileImageURL = url?.absoluteString {
                        let db = Firestore.firestore()
                        db.collection("users").document(user.uid).updateData([
                            "profileImageURL": profileImageURL
                        ]) { err in
                            if let err = err {
                                print("Error updating document: \(err)")
                            } else {
                                print("Document successfully updated")
                            }
                        }
                    }
                }
            }
        }
    }
}
