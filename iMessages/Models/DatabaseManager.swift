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
    public func createNewChatWith(with user: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> (Void)) {
        guard let currentEmail = UserDefaults.standard.value(forKey: K.Database.emailAddress) else {
            return
        }
        
        let safeEmail = ChatUser.getSafeEmail(with: currentEmail as! String)
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            
            switch firstMessage.kind {
            case .text(let text):
                message = text
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            let newConversation: [String: Any] = [
                "id": conversationID,
                "receiver_user": user,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                conversations.append(newConversation)
                userNode["conversations"] = conversations
                
            } else {
                userNode["conversations"] = [
                    newConversation
                ]
            }
            
            self.database.child(safeEmail).setValue(userNode, withCompletionBlock: { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                self.finishCreatingChat(with: conversationID, name: name, firstMessage: firstMessage, completion: completion)
            })
        })
    }
    
    private func finishCreatingChat(with conversationID: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> (Void)) {
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        
        switch firstMessage.kind {
        case .text(let text):
            message = text
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let currentUser = UserDefaults.standard.value(forKey: K.Database.emailAddress) as? String else {
            completion(false)
            return
        }
        
        let safeEmail = ChatUser.getSafeEmail(with: currentUser)
        
        let collectionMessage: [String: Any] = [
            "id": conversationID,
            "type": firstMessage.kind.messageKindString,
            "name": name,
            "content": message,
            "date": dateString,
            "sender_email": safeEmail,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        database.child(conversationID).setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            
            completion(true)
        })
    }
    
    public func getAllChats(for email: String, completion: @escaping (Result<String, Error> ) -> (Void)) {
        
    }
    
    public func getAllMessagesForChar(with id: String, completion: @escaping (Result<String, Error>) -> (Void)) {
        
    }
    
    public func sendMessage(with message: Message, to conversation: String, completion: @escaping (Bool) -> (Void)) {
        
    }
}
