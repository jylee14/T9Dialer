//
//  T9ViewController.swift
//  T9 Dialer
//
//  Created by Jun Lee on 8/30/17.
//  Copyright © 2017 Jun Lee. All rights reserved.
//

import UIKit
import Contacts
import CoreData

class T9ViewController: UIViewController {
    //OUTLET connections
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var syncButton: UIBarButtonItem!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    //APPLICATION LOGIC VARIABLES
    fileprivate let context = AppDelegate.viewContext   //database context
    fileprivate var searchBarTimer = Timer()    //to manage DB lookups
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        searchBar.delegate = self
    }
    
    //tells the app to look through the stock contacts and initialize each contact with t9 value
    @IBAction func syncContacts(_ sender: Any) {
        if sender is UIBarButtonItem{
            spinner.startAnimating()
            
            let contacts = CNContactStore() //contact store
            var permission = CNContactStore.authorizationStatus(for: .contacts) //does the app have permission right now?
            
            guard permission != .denied && permission != .restricted else {
                //alert the user that this app needs contacts permission
                return
            }
            
            if permission == .notDetermined{    //ask we dont have permission currently
                contacts.requestAccess(for: .contacts){(status, error) in
                    if status {
                        permission = .authorized
                    }else{
                        permission = .denied
                        //alert the user that the app needs contact access
                        return
                    }
                }
            }
            
            if permission == .authorized{
                DispatchQueue.global(qos: .userInitiated).async{ [unowned self] in
                    var contactsArray:[CNContact] = []   //fetched contacts
                    let contactKeys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]    //fetch key
                    let contactsRequest = CNContactFetchRequest(keysToFetch: contactKeys)   //fetch request
                    
                    do{
                        try contacts.enumerateContacts(with: contactsRequest){ (contact, _) in
                            contactsArray.append(contact)
                        }
                    }catch{
                        print("failed to sync contacts")
                        //alert the user of failure
                    }
                    
                    let assignedContacts = self.assignT9ValueTo(contactsArray)
                    for contact in assignedContacts{
                        let person = Contact(context: self.context)
                        person.name = contact.name
                        person.number = contact.number
                        person.t9 = contact.t9
                        
                        try? self.context.save()
                    }
                    
                }
            }
        }
    }
    
    private let T9Value: [Character: Int] = [
        "a": 2, "b": 2, "c": 2,
        "d": 3, "e": 3, "f": 3,
        "g": 4, "h": 4, "i": 4,
        "j": 5, "k": 5, "l": 5,
        "m": 6, "n": 6, "o": 6,
        "p": 7, "q": 7, "r": 7, "s": 7,
        "t": 8, "u": 8, "v": 8,
        "w": 9, "x": 9, "y": 9, "z": 9
    ]
    private func assignT9ValueTo(_ contacts: [CNContact])->[(name: String, number: String, t9: String)]{
        var T9ContactsArray:[(String, String, String)] = []
        for contact in contacts{
            let name = contact.givenName.lowercased() + contact.familyName.lowercased() //dictionary expects lower cased string
            var t9value = ""
            
            for char in name.characters{
                t9value.append(String(T9Value[char]!))
            }
            T9ContactsArray.append((name, contact.phoneNumbers[0].value.stringValue, t9value))
        }
        
        return T9ContactsArray
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
