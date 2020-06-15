//
//  ContactCell.swift
//  T9 Dialer
//
//  Created by Jun Lee on 8/30/17.
//  Copyright © 2017 Jun Lee. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {
    @IBOutlet weak var contactPhoto: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var number: UILabel!
    @IBOutlet weak var callButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if #available(iOS 13, *) {
            callButton.setImage(UIImage(systemName: "phone"), for: .normal)
            callButton.setTitle("", for: .normal)
        } else {
            callButton.setTitle("Call", for: .normal)
        }
    }
    
    @IBAction func call(_ sender: UIButton) {
        guard let phoneNumber = number.text else { return }
        let clearedNumber = clearPhoneNumber(phoneNumber)
        
        if let telURL = URL(string: "tel://\(clearedNumber)") {
            if UIApplication.shared.canOpenURL(telURL) {
                UIApplication.shared.open(telURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func clearPhoneNumber(_ number: String)->String{
        var processedNumber = ""
        for char in number{
            if "0"..."9" ~= char{ // make sure that its a number
                processedNumber.append(char)
            }
        }
        
        return processedNumber
    }
}
