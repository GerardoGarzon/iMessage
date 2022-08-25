//
//  ChatUser.swift
//  iMessages
//
//  Created by Gerardo Garzon on 23/08/22.
//

import Foundation

struct ChatUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    var safeEmail: String {
        var email = emailAddress.replacingOccurrences(of: ".", with: "-")
        email = email.replacingOccurrences(of: "@", with: "-")
        return email
    }
    var profilePicture: String {
        return "\(safeEmail)_profile_picture.png"
    }
    // let profilePictureURL: String
    
}
