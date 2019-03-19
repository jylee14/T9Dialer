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
    @IBOutlet weak var contactsView: UITableView!
    
    //APPLICATION LOGIC VARIABLES
    fileprivate let context = AppDelegate.viewContext   //database context
    fileprivate var searchBarTimer = Timer()    //to manage DB lookups
    fileprivate var currentSearchNumber = ""    //what the user is current searching for
    fileprivate var searchResult: [Contact]? = nil{
        didSet{
            contactsView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        searchBar.delegate = self
        contactsView.delegate = self
        contactsView.dataSource = self
    }
    
    
    //tells the app to look through the stock contacts and initialize each contact with t9 value
    @IBAction func syncContacts(_ sender: Any) {
        if sender is UIBarButtonItem{
            spinner.isHidden = false
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
                clearDatabase() //only while i figure out how to make the DB sync non-duplicate entities
                
                DispatchQueue.global(qos: .userInitiated).async{ [unowned self] in
                    var contactsArray:[CNContact] = []   //fetched contacts
                    let contactKeys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey] as [CNKeyDescriptor]    //fetch key
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
                        person.photo = contact.photo
                        
                        try? self.context.save()
                    }
                 
                    DispatchQueue.main.async { [weak self] in
                        self?.spinner.stopAnimating()
                        self?.spinner.isHidden = true
                    }
                }
            }
        }
    }
    
    private func clearDatabase(){
        let fetchRequest:NSFetchRequest<Contact> = Contact.fetchRequest()
        do{
            let results = try context.fetch(fetchRequest)
            for contact in results{
                context.delete(contact as NSManagedObject)
            }
        }catch{}
    }
    
    private let T9Value: [Character: Int] = [
        "a": 2, "b": 2, "c": 2,
        "d": 3, "e": 3, "f": 3,
        "g": 4, "h": 4, "i": 4,
        "j": 5, "k": 5, "l": 5,
        "m": 6, "n": 6, "o": 6,
        "p": 7, "q": 7, "r": 7, "s": 7,
        "t": 8, "u": 8, "v": 8,
        "w": 9, "x": 9, "y": 9, "z": 9]
    
    private func assignT9ValueTo(_ contacts: [CNContact])->[ContactItem]{
        var T9ContactsArray:[ContactItem] = []
        for contact in contacts{
            let name = contact.givenName.lowercased() + " " + contact.familyName.lowercased() //dictionary expects lower cased string
            var t9value = ""
            
            for char in name{
                if char == " " { continue }
                t9value.append(String(T9Value[char]!))
            }
            
            guard contact.phoneNumbers.count > 0 else { continue }  //theres no phone number, don't process this one 
            let tempContact = ContactItem(name: name, number: contact.phoneNumbers[0].value.stringValue, t9: t9value, photo: contact.imageData)
            T9ContactsArray.append(tempContact)
        }
        
        return T9ContactsArray
    }
    
    //search for the given numeric sequence
    fileprivate func search(_ text: String = ""){
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true), NSSortDescriptor(key: "number", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "t9 contains %@", text)
        
        searchResult = try? context.fetch(fetchRequest)
    }
}

//implementing tableView logic for contact search list
extension T9ViewController: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResult?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Contact", for: indexPath)
        
        if let contacts = searchResult, let contactCell = cell as? ContactCell{
            if let imageData = contacts[indexPath.row].photo {
                contactCell.contactPhoto.image = UIImage(data: imageData as Data)
            }else{
                contactCell.contactPhoto.image = #imageLiteral(resourceName: "default")
            }
            contactCell.name.text = contacts[indexPath.row].name
            contactCell.number.text = contacts[indexPath.row].number
        }
        
        return cell
    }
}


//implementing search bar capabilities
extension T9ViewController: UISearchBarDelegate{
    //what happens when the user cancels search,
    //should clear search field and display all items
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        search()
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
        search()
        searchBarTimer.invalidate()
    }
    
    //function that searches for the term in the searchbox
    @objc private func startSearch(){
        if let searchBarText = searchBar.text{
            if searchBarText != currentSearchNumber{
                currentSearchNumber = searchBarText
                search(searchBarText)
            }
        }
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
}
