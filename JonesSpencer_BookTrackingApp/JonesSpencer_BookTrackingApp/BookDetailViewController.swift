//  BookDetailViewController.swift
//  JonesSpencer_BookTrackingApp
//  Created by Spencer Jones on 6/4/24.

import UIKit

class BookDetailViewController: UIViewController {
    
    @IBOutlet var bookImage: UIImageView!
    
    @IBOutlet var bookTitle: UILabel!
    @IBOutlet var BookAuthor: UILabel!
    @IBOutlet var bookRating: UILabel!
    @IBOutlet var bookDescription: UILabel!
    
    var book: Book?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    func configureView() {
        guard let book = book else { return }
        bookTitle.text = book.title
        BookAuthor.text = book.authors?.joined(separator: ", ")
        bookDescription.text = book.description
        
        // Display average rating if available
        if let rating = book.averageRating {
            bookRating.text = "\(rating)"
        } else {
            bookRating.text = "Rating: Not available"
        }
        
        if let thumbnail = book.thumbnail, let url = URL(string: thumbnail) {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    DispatchQueue.main.async {
                        self.bookImage.image = UIImage(data: data)
                    }
                }
            }
            task.resume()
        } else {
            bookImage.image = UIImage(named: "defaultBookCover")
        }
    }
}
