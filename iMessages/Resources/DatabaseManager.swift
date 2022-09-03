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
    
    public func getUserInfo(with user: String, completion: @escaping (Result<[String: Any], Error>) -> (Void)) {
        let email = ChatUser.getSafeEmail(with: user)
        database.child(email).observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else {
                completion(.failure(DatabaseManager.UsersError.failedToFetch))
                return
            }
            completion(.success(value))
        }
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
    public func createNewChatWith(with user: String, name: String, firstMessage: Message, completion: @escaping (Bool, String) -> (Void)) {
        guard let currentEmail = UserDefaults.standard.value(forKey: K.Database.emailAddress),
              let displayedName = UserDefaults.standard.value(forKey: K.Database.displayedName) else {
            return
        }
        
        let safeEmail = ChatUser.getSafeEmail(with: currentEmail as! String)
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: {[weak self] snapshot in
            guard let strongSelf = self else {
                return
            }
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false, "")
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
            
            let receiver_newConversation: [String: Any] = [
                "id": conversationID,
                "receiver_user": safeEmail,
                "name": displayedName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            strongSelf.database.child(user).observeSingleEvent(of: .value, with: { snapshot in
                guard var userNode = snapshot.value as? [String: Any] else {
                    completion(false, "")
                    return
                }
                
                if var conversations = userNode["conversations"] as? [[String: Any]] {
                    conversations.append(receiver_newConversation)
                    userNode["conversations"] = conversations
                    
                } else {
                    userNode["conversations"] = [
                        receiver_newConversation
                    ]
                }
                
                strongSelf.database.child(user).setValue(userNode)
            })
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                conversations.append(newConversation)
                userNode["conversations"] = conversations
                
            } else {
                userNode["conversations"] = [
                    newConversation
                ]
            }
            
            strongSelf.database.child(safeEmail).setValue(userNode, withCompletionBlock: { error, _ in
                guard error == nil else {
                    completion(false, "")
                    return
                }
                strongSelf.finishCreatingChat(with: conversationID, name: name, firstMessage: firstMessage, completion: completion)
            })
        })
    }
    
    private func finishCreatingChat(with conversationID: String, name: String, firstMessage: Message, completion: @escaping (Bool, String) -> (Void)) {
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
            completion(false, "")
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
                completion(false, "")
                return
            }
            
            completion(true, conversationID)
        })
    }
    
    public func getAllChats(for email: String, completion: @escaping (Result<[Contact], Error> ) -> (Void)) {
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseManager.UsersError.failedToFetch))
                return
            }
            let conversations: [Contact] = value.compactMap({ dictonary in
                guard let conversationID = dictonary["id"] as? String,
                      let name = dictonary["name"] as? String,
                      let userEmail = dictonary["receiver_user"] as? String,
                      let latestMessage = dictonary["latest_message"] as? [String: Any],
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool,
                      let date = latestMessage["date"] as? String else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                
                return Contact(id: conversationID, name: name, lastMessage: latestMessageObject, userEmail: userEmail)
            })
            completion(.success(conversations))
        })
    }
    
    public func getAllMessagesForChar(with id: String, completion: @escaping (Result<[Message], Error>) -> (Void)) {
        database.child("\(id)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseManager.UsersError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                guard let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let date = dictionary["date"] as? String,
                      // let isRead = dictionary["is_read"] as? Bool,
                      let name = dictionary["name"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let sentDate = ChatViewController.dateFormatter.date(from: date) else {
                    completion(.failure(DatabaseManager.UsersError.failedToFetch))
                    return nil
                }
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                return Message(sender: sender, messageId: messageID, sentDate: sentDate, kind: .text(content))
            })
            completion(.success(messages))
        }
    }
    
    public func sendMessage(with message: Message, to conversationID: String, receiverEmail: String, userName: String, completion: @escaping (Bool) -> (Void)) {
        database.child("\(conversationID)/messages").observeSingleEvent(of: .value) { snapshot in
            guard var value = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            guard let currentUser = UserDefaults.standard.value(forKey: K.Database.emailAddress) as? String else {
                return
            }
            
            let safeEmail = ChatUser.getSafeEmail(with: currentUser)
            
            let newMessage: [String: Any] = [
                "id": conversationID,
                "type": message.kind.messageKindString,
                "name": userName,
                "content": message.kind.messageContent!,
                "date": ChatViewController.dateFormatter.string(from: message.sentDate),
                "sender_email": safeEmail,
                "is_read": false
            ]
            
            value.append(newMessage)
            
            self.database.child("\(conversationID)/messages").setValue(value)
            
            self.updateUserConversations(for: safeEmail, with: conversationID, message: newMessage) { success in
                if !success {
                    print("error")
                }
            }
            self.updateUserConversations(for: receiverEmail, with: conversationID, message: newMessage) { success in
                if !success {
                    print("error")
                }
            }
            
            completion(true)
        }
    }
    
    public func updateUserConversations(for user: String, with conversationID: String, message: [String: Any], completion: @escaping (Bool) -> (Void)) {
        database.child("\(user)/conversations").observeSingleEvent(of: .value) { snapshot in
            guard var value = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            var count = 0
            for conversation in value {
                if let id = conversation["id"] as? String, id == conversationID {
                    break
                }
                count += 1
            }
            
            guard let date = message["date"] as? String,
                  let text = message["content"] as? String,
                  let receiver_user = value[count]["receiver_user"] as? String,
                  let name = value[count]["name"] as? String else {
                completion(false)
                return
            }
            
            value[count] = [
                "id": conversationID,
                "receiver_user": receiver_user,
                "name": name,
                "latest_message": [
                    "date": date,
                    "is_read": false,
                    "message": text
                ]
            ]
            
            self.database.child("\(user)/conversations").setValue(value)
            completion(true)
            
        }
    }
    
    public func conversationExist(for sender: String, with otherUser: String, completion: @escaping (Result<String, Error>) -> (Void)) {
        database.child("\(sender)/conversations").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(UsersError.failedToFetch))
                return
            }
            let conversation: [String] = value.compactMap { element in
                guard let user = element["receiver_user"] as? String,
                    let id = element["id"] as? String else {
                    return nil
                }
                
                if user == otherUser {
                    return id
                } else {
                    return nil
                }
            }
            
            if conversation.isEmpty {
                completion(.failure(UsersError.failedToFetch))
            } else {
                completion(.success(conversation[0]))
            }
        }
    }
}
