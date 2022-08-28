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
        let email = ChatUser.getSafeEmail(with: user)
        database.child(email).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? [String: Any] != nil else {
                completion(false)
                return
            }
            
            completion(true)
        })
    }
    
    public func insertUser(with user: ChatUser, completion: @escaping (Bool) -> (Void)) {
        database.child(user.safeEmail).setValue([
            K.Database.firstName: user.firstName,
            K.Database.lastName: user.lastName,
            K.Database.emailAddress: user.emailAddress
        ], withCompletionBlock: { error, databaseReference in
            guard error == nil else {
                completion(false)
                return
            }
            
            self.database.child(K.Database.usersChild).observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    // Append users
                    usersCollection.append([
                        K.Database.nameField: user.firstName + " " + user.lastName,
                        K.Database.emailField: user.safeEmail
                    ])
                    
                    self.database.child(K.Database.usersChild).setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                } else {
                    // Create new array
                    let newCollection: [[String: String]] = [
                        [
                            K.Database.nameField: user.firstName + " " + user.lastName,
                            K.Database.emailField: user.safeEmail
                        ]
                    ]
                    
                    self.database.child(K.Database.usersChild).setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                }
            })
        })
    }
    
    public func readUsersCollection(completion: @escaping (Result<[[String: String]], Error>) -> (Void)) {
        database.child(K.Database.usersChild).observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(UsersError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    public enum UsersError: Error{
        case failedToFetch
    }
    
}

// MARK: - Messages managment extension database

extension DatabaseManager {
    public func createNewChatWith(with user: String, firstMessage: Message, completion: @escaping (Bool) -> (Void)) {
        
    }
    
    public func getAllChats(for email: String, completion: @escaping (Result<String, Error> ) -> (Void)) {
        
    }
    
    public func getAllMessagesForChar(with id: String, completion: @escaping (Result<String, Error>) -> (Void)) {
        
    }
    
    public func sendMessage(with message: Message, to conversation: String, completion: @escaping (Bool) -> (Void)) {
        
    }
}
