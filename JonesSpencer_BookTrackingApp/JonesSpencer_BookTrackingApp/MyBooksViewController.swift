//  MyBooksViewController.swift
//  JonesSpencer_BookTrackingApp
//  Created by Spencer Jones on 6/4/24.

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabaseInternal
import FirebaseDatabase

// Global private constant for resuse id
private let myBooksCell = "MyBooksCell"

class MyBooksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var books: [Book] = []
    var filteredBooks: [Book] = []
    
    // Search oulets
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    
    let db = Firestore.firestore()
    let realTimeDB = Database.database().reference()
    
    var userId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        fetchUserBooks()
        
    }
    
    func fetchUserBooks() {
        guard let userId = userId else {
            print("User ID is nil")
            return
        }
        
        print("Fetching books for userId: \(userId)")
        
        db.collection("books")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting documents: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found for userId: \(userId)")
                    return
                }
                
                self.books = documents.map { document in
                    let data = document.data()
                    print("Document data: \(data)")
                    
                    let title = data["title"] as? String ?? ""
                    let authors = data["author"] as? [String]
                    let description = data["genre"] as? String
                    let genre = data["genre"] as? String
                    let isbn = data["isbn"] as? String
                    let language = data["language"] as? String
                    let publisher = data["publisher"] as? String
                    let pages = String(data["pages"] as? Int ?? 0)
                    let isPublic = data["public"] as? Bool ?? false
                    let thumbnail = data["thumbnail"] as? String
                    let averageRating = data["rating"] as? Double ?? 0.0
                    let userId = data["userId"] as? String
                    
                    return Book(
                        title: title,
                        authors: authors,
                        description: description,
                        genre: genre,
                        isbn: isbn,
                        language: language,
                        publisher: publisher,
                        pages: pages,
                        public: isPublic,
                        thumbnail: thumbnail,
                        averageRating: averageRating,
                        userId: userId
                    )
                }
                
                print("Fetched \(self.books.count) books for userId: \(userId)")
                
                self.filteredBooks = self.books
                
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    // MARK: UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredBooks = books
        } else {
            filteredBooks = books.filter { book in
                return book.title.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }
    
    @objc func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    
    // MARK: Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return  1
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return books.count
        return filteredBooks.count
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue reusable cell with identifier "feedCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: myBooksCell, for: indexPath) as? MyBooksTableViewCell else {
            // If cell is not of type myBooksCell, return default cell
            return tableView.dequeueReusableCell(withIdentifier: myBooksCell, for: indexPath)
        }
        
        let book = filteredBooks[indexPath.row]
        
        cell.bookTitle.text = book.title
        
        // Display the first author's name
        if let firstAuthor = book.authors?.first {
            cell.bookAuthor.text = firstAuthor
        } else {
            cell.bookAuthor.text = "Unknown Author"
        }
        
        cell.bookGenre.text = book.description
        cell.bookPages.text = book.pages
        
        
        // Set the book cover image
        if let thumbnail = book.thumbnail, let url = URL(string: thumbnail) {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    DispatchQueue.main.async {
                        cell.bookImage.image = UIImage(data: data)
                    }
                }
            }
            task.resume()
        } else {
            cell.bookImage.image = UIImage(named: "defaultBookCover")
        }
        
        // Set the rating stars
        cell.setRatingStars(rating: book.averageRating)
        
        return cell
    }
    
    // Set height of cell
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    // MARK: Table view delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowAddBookReview" {
            if let addBookVC = segue.destination as? AddBookReviewViewController {
                addBookVC.delegate = self
            }
        }
    }
}

extension MyBooksViewController: AddBookReviewViewControllerDelegate {
    func didAddBook(_ book: Book) {
        self.books.append(book)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
