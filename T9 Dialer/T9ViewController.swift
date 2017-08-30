//
//  T9ViewController.swift
//  T9 Dialer
//
//  Created by Jun Lee on 8/30/17.
//  Copyright © 2017 Jun Lee. All rights reserved.
//

import UIKit
import CoreData

class T9ViewController: UIViewController {
    //OUTLET connections
    @IBOutlet weak var searchBar: UISearchBar!
    
    //APPLICATION LOGIC VARIABLES
    fileprivate let context = AppDelegate.viewContext   //database context
    fileprivate var searchBarTimer = Timer()    //to manage DB lookups
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        searchBar.delegate = self
    }
}

extension T9ViewController: UISearchBarDelegate{
    //what happens when the user cancels search,
    //should clear search field and display all items
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.resignFirstResponder()
    }
    
    //what happens when the user taps on the search button
    //should update the search result to reflect what the user is typing
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBarTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(startSearch), userInfo: nil, repeats: true)
    }
    
    //the searchbar is no longer key item, stop the timer to minimize performance hit
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBarTimer.invalidate()
    }
    
    //function that searches for the term in the searchbox
    @objc private func startSearch(){
        print("search...")
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
}
