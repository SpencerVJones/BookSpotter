//  MainTabBarController.swift
//  JonesSpencer_BookTrackingApp
//  Created by Spencer Jones on 6/24/24.

import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        // Set initial selected view controller
        self.selectedIndex = 0
    }
}
