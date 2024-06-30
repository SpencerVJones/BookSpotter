//  CreateBookViewController.swift
//  JonesSpencer_BookTrackingApp
//  Created by Spencer Jones on 6/4/24.

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabaseInternal

class AddBookReviewViewController: UIViewController , UITextFieldDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet var bookImage: UIImageView!
    @IBOutlet var editBookImage: UIButton!
    @IBOutlet var bookTitleField: UITextField!
    @IBOutlet var bookAuthorField: UITextField!
    @IBOutlet var bookGenreField: UITextField!
    @IBOutlet var bookISBNField: UITextField!
    @IBOutlet var bookLanguageField: UITextField!
    @IBOutlet var bookPublisherField: UITextField!
    @IBOutlet var bookPagesField: UITextField!
    @IBOutlet var starsStepper: UIStepper!
    @IBOutlet var publicPrivateSegmentedControl: UISegmentedControl!
    @IBOutlet var stepperLabel: UILabel!
    
    let db = Firestore.firestore()
    let realTimeDB = Database.database().reference()
    var selectedImage: UIImage?
    let storage = Storage.storage()
    
    weak var delegate: AddBookReviewViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting delegates for text fields
        bookTitleField.delegate = self
        bookAuthorField.delegate = self
        bookGenreField.delegate = self
        bookISBNField.delegate = self
        bookLanguageField.delegate = self
        bookPublisherField.delegate = self
        bookPagesField.delegate = self
        
        // Changing return key to "Next" for all text fields except final change to "Done"
        bookTitleField.returnKeyType = .next
        bookAuthorField.returnKeyType = .next
        bookGenreField.returnKeyType = .next
        bookISBNField.returnKeyType = .next
        bookLanguageField.returnKeyType = .next
        bookPublisherField.returnKeyType = .next
        bookPagesField.returnKeyType = .done
        
        // Configure the stepper for star rating
        starsStepper.minimumValue = 0
        starsStepper.maximumValue = 5
        starsStepper.stepValue = 0.5
        starsStepper.value = 5
        
        // Set initial value for stepper label
        stepperLabel.text = "\(starsStepper.value)"
        
        // Add action for the stepper
        starsStepper.addTarget(self, action: #selector(starsStepperChanged(_:)), for: .valueChanged)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    // Action for stepper to update label
    @objc func starsStepperChanged(_ sender: UIStepper) {
        stepperLabel.text = "\(sender.value)"
    }
    
    // MARK: UITextFieldDelegate Methods
    // Dismiss keyboard when Done key is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == bookTitleField {
            bookAuthorField.becomeFirstResponder()
        }
        if textField == bookAuthorField {
            bookGenreField.becomeFirstResponder()
        }
        if textField == bookGenreField {
            bookISBNField.becomeFirstResponder()
        }
        if textField == bookISBNField {
            bookLanguageField.becomeFirstResponder()
        }
        if textField == bookLanguageField {
            bookPublisherField.becomeFirstResponder()
        }
        if textField == bookPublisherField {
            bookPagesField.becomeFirstResponder()
        }
        else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: Storyboard Actions
    @IBAction func editBookImageButton(_ sender: UIButton) {
        // Will allow user to change image
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    // Image picker delegate method to handle selected image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            bookImage.image = pickedImage
            selectedImage = pickedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    // Method to upload book image to Firebase Storage
    func uploadBookImage(completion: @escaping (_ url: String?) -> Void) {
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }
        
        let imageName = UUID().uuidString
        let imageRef = storage.reference().child("book_images/\(imageName).jpg")
        
        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            guard let _ = metadata else {
                completion(nil)
                return
            }
            
            imageRef.downloadURL { (url, error) in
                guard let downloadURL = url?.absoluteString else {
                    completion(nil)
                    return
                }
                completion(downloadURL)
            }
        }
    }
    
    
    @IBAction func addBookButton(_ sender: UIButton) {
        guard let title = bookTitleField.text, !title.isEmpty,
              let author = bookAuthorField.text, !author.isEmpty else {
            print("Title or author is empty")
            return
        }
        
        let pages = Int(bookPagesField.text ?? "") ?? 0
        let rating = starsStepper.value
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }
        
        // Upload image and then add book data to Firestore
        uploadBookImage { [weak self] imageUrl in
            guard let self = self else { return }
            
            let bookData: [String: Any] = [
                "title": title,
                "author": [author],
                "genre": self.bookGenreField.text ?? "",
                "isbn": self.bookISBNField.text ?? "",
                "language": self.bookLanguageField.text ?? "",
                "publisher": self.bookPublisherField.text ?? "",
                "pages": pages,
                "public": self.publicPrivateSegmentedControl.selectedSegmentIndex == 0,
                "rating": rating,
                "userId": userId,
                "thumbnail": imageUrl ?? "" // Add image URL to Firestore
            ]
            
            // Add to Firestore
            self.db.collection("books").addDocument(data: bookData) { error in
                if let error = error {
                    print("Error adding document: \(error)")
                } else {
                    print("Document added successfully to Firestore")
                    
                    let book = Book(
                        title: title,
                        authors: [author],
                        description: bookData["genre"] as? String ?? "",
                        genre: bookData["genre"] as? String,
                        isbn: bookData["isbn"] as? String,
                        language: bookData["language"] as? String,
                        publisher: bookData["publisher"] as? String,
                        pages: String(pages),
                        public: bookData["public"] as? Bool,
                        thumbnail: bookData["thumbnail"] as? String,
                        averageRating: rating,
                        userId: userId
                    )
                    self.delegate?.didAddBook(book)
                    
                    DispatchQueue.main.async {
                        // Show alert that book was added
                        let alert = UIAlertController(title: "Book Added", message: "Your book has been successfully added!", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        
                        // Reload table view in FeedViewController if it's presented
                        if let feedVC = self.tabBarController?.viewControllers?.first(where: { $0 is FeedViewController }) as? FeedViewController {
                            feedVC.fetchPublicBooks()
                        }
                    }
                }
            }
        }
    }
}

protocol AddBookReviewViewControllerDelegate: AnyObject {
    func didAddBook(_ book: Book)
}
