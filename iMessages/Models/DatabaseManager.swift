//
//  DatabaseManager.swift
//  iMessages
//
//  Created by Gerardo Garzon on 22/08/22.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()

    // MARK: - User managment
    
    public func userExists(with user: String, completion: @escaping ((Bool) -> Void)) {
        var email = user.replacingOccurrences(of: ".", with: "-")
        email = email.replacingOccurrences(of: "@", with: "-")
        database.child(K.Database.usersChild).child(email).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.value != nil {
                completion(false)
            } else {
                completion(true)
            }
        })
    }
    
    public func insertUser(with user: ChatUser, completion: @escaping (Bool) -> (Void)) {
        database.child(K.Database.usersChild).child(user.safeEmail).setValue([
            K.Database.firstName: user.firstName,
            K.Database.lastName: user.lastName,
            K.Database.emailAddress: user.emailAddress
        ], withCompletionBlock: { error, databaseReference in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
}
