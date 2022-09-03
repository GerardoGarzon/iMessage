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
        return ChatUser.getSafeEmail(with: emailAddress)
    }
    var profilePicture: String {
        return ChatUser.getProfilePictureName(with: safeEmail)
    }
    
    static func getSafeEmail(with emailAddress: String) -> String {
        var email = emailAddress.replacingOccurrences(of: ".", with: "-")
        email = email.replacingOccurrences(of: "@", with: "-")
        return email
    }
    
    static func getProfilePictureName(with safeEmail: String) -> String {
        return "\(safeEmail)_profile_picture.png"
    }
}
