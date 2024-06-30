//  Book.swift
//  JonesSpencer_BookTrackingApp
//  Created by Spencer Jones on 6/19/24.

import Foundation

struct Book: Codable {
    var title: String
    var authors: [String]?
    var description: String?
    var genre: String?
    var isbn: String?
    var language: String?
    var publisher: String?
    var pages: String?
    var `public`: Bool?
    var thumbnail: String?
    var averageRating: Double?
    var userId: String?
}
