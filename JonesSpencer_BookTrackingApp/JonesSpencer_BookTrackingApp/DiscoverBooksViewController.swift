//  DiscoverBooksViewController.swift
//  JonesSpencer_BookTrackingApp
//  Created by Spencer Jones on 6/4/24.

import UIKit

// Global private constant for resuse id
private let discoverBooksCell = "DiscoverCell"

class DiscoverBooksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    // Search bar outlets
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    
    var books: [Book] = []
    var filteredBooks: [Book] = []
    
    let apiKey = "AIzaSyDXSehyrETsma2JnTLEbeIUrH1lyZztLCw"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        fetchBookData()
    }
    
    // MARK: Fetch Data
    func fetchBookData() {
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=best+sellers&orderBy=relevance&maxResults=20&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let items = json["items"] as? [[String: Any]] {
                    
                    for item in items {
                        if let volumeInfo = item["volumeInfo"] as? [String: Any],
                           let title = volumeInfo["title"] as? String,
                           let authors = volumeInfo["authors"] as? [String],
                           let description = volumeInfo["description"] as? String,
                           let imageLinks = volumeInfo["imageLinks"] as? [String: Any],
                           let thumbnail = imageLinks["thumbnail"] as? String,
                           let averageRating = volumeInfo["averageRating"] as? Double {
                            
                            // Initialize Book object
                            let book = Book(title: title,
                                            authors: authors,
                                            description: description,
                                            genre: nil,
                                            isbn: nil,
                                            language: nil,
                                            publisher: nil,
                                            pages: nil,
                                            public: nil,
                                            thumbnail: thumbnail,
                                            averageRating: averageRating,
                                            userId: nil)
                            
                            // Append the book to the array
                            self.books.append(book)
                            self.filteredBooks = self.books
                            
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            } catch {
                print("JSON serialization error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: discoverBooksCell, for: indexPath) as? DiscoverBooksTableViewCell else {
            // If cell is not of type feedCell, return default cell
            return tableView.dequeueReusableCell(withIdentifier: discoverBooksCell, for: indexPath)
        }
        
        let book = filteredBooks[indexPath.row]
        
        cell.bookTitle.text = book.title
        cell.author.text = book.authors?.joined(separator: ", ")
        cell.genre.text = book.description
        
        // Set book cover image
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
        let selectedBook = books[indexPath.row]
        performSegue(withIdentifier: "showBookDetail", sender: selectedBook)
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBookDetail",
           let destinationVC = segue.destination as? BookDetailViewController,
           let selectedBook = sender as? Book {
            destinationVC.book = selectedBook
        }
    }
}
