//  FeedViewController.swift
//  JonesSpencer_BookTrackingApp
//  Created by Spencer Jones on 6/4/24.

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

// Global private constant for resuse id
private let feedCell = "FeedCell"

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,UITabBarDelegate, UISearchBarDelegate {
    
    // Outlets
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    
    
    var books: [Book] = []
    var filteredBooks: [Book] = []
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        fetchPublicBooks()
    }
    
    
    // MARK: Fetch Data
    func fetchPublicBooks() {
        print("Fetching public books")
        
        db.collection("books")
            .whereField("public", isEqualTo: true)
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    if let documents = querySnapshot?.documents {
                        self.books = documents.compactMap { document in
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
                        
                        self.filteredBooks = self.books
                        
                        print("Fetched \(self.books.count) public books")
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    } else {
                        print("No public documents found")
                    }
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: feedCell, for: indexPath) as? FeedTableViewCell else {
            // If cell is not of type feedCell, return default cell
            return tableView.dequeueReusableCell(withIdentifier: feedCell, for: indexPath)
        }
        
        let book = filteredBooks[indexPath.row]
        
        cell.bookTitle.text = book.title
        
        // Display authors if available
        if let authors = book.authors, !authors.isEmpty {
            cell.bookAuthor.text = authors.joined(separator: ", ")
        } else {
            cell.bookAuthor.text = "Unknown Author"
        }
        
        cell.bookGenre.text = book.description
        
        // Set the book cover image
        if let thumbnail = book.thumbnail, let url = URL(string: thumbnail) {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    DispatchQueue.main.async {
                        cell.bookCover.image = UIImage(data: data)
                    }
                }
            }
            task.resume()
        } else {
            cell.bookCover.image = UIImage(named: "defaultBookCover")
        }
        
        // Set rating stars
        cell.setRatingStars(rating: book.averageRating)
        
        return cell
    }
    
    // Set height of cell
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    // MARK: Table view delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

extension FeedViewController: AddBookReviewViewControllerDelegate {
    func didAddBook(_ book: Book) {
        if book.public == true {
            self.books.append(book)
            self.filteredBooks.append(book)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}
