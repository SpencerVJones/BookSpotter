//  DiscoverBooksTableViewCell.swift
//  JonesSpencer_BookTrackingApp
//  Created by Spencer Jones on 6/4/24.

import UIKit

class DiscoverBooksTableViewCell: UITableViewCell {
    
    @IBOutlet var bookTitle: UILabel!
    @IBOutlet var author: UILabel!
    @IBOutlet var genre: UILabel!
    @IBOutlet var language: UILabel!
    
    
    @IBOutlet var star1: UIImageView!
    @IBOutlet var star2: UIImageView!
    @IBOutlet var star3: UIImageView!
    @IBOutlet var star4: UIImageView!
    @IBOutlet var star5: UIImageView!
    
    @IBOutlet var bookImage: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setRatingStars(rating: Double?) {
        guard let rating = rating else {
            // Set all stars to empty
            star1.image = UIImage(systemName: "star")
            star2.image = UIImage(systemName: "star")
            star3.image = UIImage(systemName: "star")
            star4.image = UIImage(systemName: "star")
            star5.image = UIImage(systemName: "star")
            return
        }
        
        // Set filled stars
        let filledStar = UIImage(systemName: "star.fill")
        let halfStar = UIImage(systemName: "star.lefthalf.fill")
        let emptyStar = UIImage(systemName: "star")
        
        let stars = [star1, star2, star3, star4, star5]
        
        for i in 0..<5 {
            if Double(i + 1) <= rating {
                stars[i]?.image = filledStar
            } else if Double(i) + 0.5 <= rating {
                stars[i]?.image = halfStar
            } else {
                stars[i]?.image = emptyStar
            }
        }
    }
}
