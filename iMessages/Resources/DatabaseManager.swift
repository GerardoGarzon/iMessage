//
//  DatabaseManager.swift
//  iMessages
//
//  Created by Gerardo Garzon on 22/08/22.
//

import Foundation
import FirebaseDatabase
import MessageKit
import CoreLocation

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
            guard let message = firstMessage.kind.messageContent else {
                completion(false, "")
                return
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversation: [String: Any] = [
                "id": conversationID,
                "receiver_user": user,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                    "type": firstMessage.kind.messageKindString
                ]
            ]
            
            let receiver_newConversation: [String: Any] = [
                "id": conversationID,
                "receiver_user": safeEmail,
                "name": displayedName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                    "type": firstMessage.kind.messageKindString
                ]
            ]
            
            strongSelf.database.child(user).observeSingleEvent(of: .value, with: { snapshot in
                guard var userNode = snapshot.value as? [String: Any] else {
                    completion(false, "")
                    return
                }
                
                if var conversations = userNode["conversations"] as? [[String: Any]] {
                    var conversationExist: Bool = false
                    var conversationIndex: Int = 0
                    for conversation in conversations {
                        if conversation["id"] as? String == conversationID {
                            conversationExist = true
                            break
                        }
                        conversationIndex += 1
                    }
                    if !conversationExist {
                        conversations.append(newConversation)
                        userNode["conversations"] = conversations
                    } else {
                        conversations[conversationIndex]["latest_message"] = newConversation["latest_message"]
                        userNode["conversations"] = conversations
                    }
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
        guard let message = firstMessage.kind.messageContent else {
            return
        }
        
        guard let currentUser = UserDefaults.standard.value(forKey: K.Database.emailAddress) as? String else {
            completion(false, "")
            return
        }
        
        let safeEmail = ChatUser.getSafeEmail(with: currentUser)
        
        var collectionMessage: [String: Any] = [
            "id": conversationID,
            "type": firstMessage.kind.messageKindString,
            "name": name,
            "content": message,
            "date": dateString,
            "sender_email": safeEmail,
            "is_read": false
        ]
        
        if let duration = firstMessage.audioDuration {
            collectionMessage["duration"] = duration
        }
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        database.child("\(conversationID)/messages").observeSingleEvent(of: .value) { snapshot in
            if var array = snapshot.value as? [[String: Any]] {
                array.append(collectionMessage)
                self.database.child("\(conversationID)/messages").setValue(array, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false, "")
                        return
                    }
                    
                    completion(true, conversationID)
                })
            } else {
                self.database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false, "")
                        return
                    }
                    
                    completion(true, conversationID)
                })
            }
        }
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
                      let type = latestMessage["type"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool,
                      let date = latestMessage["date"] as? String else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead, type: type)
                
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
                      let type = dictionary["type"] as? String,
                      let name = dictionary["name"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let sentDate = ChatViewController.dateFormatter.date(from: date) else {
                    completion(.failure(DatabaseManager.UsersError.failedToFetch))
                    return nil
                }
                
                var kind: MessageKind?
                var audio: Audio?
                if type == "text" {
                    kind = .text(content)
                } else if type == "photo" {
                    guard let url = URL(string: content),
                          let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else if type == "video" {
                    guard let url = URL(string: content),
                          let placeholder = UIImage(named: "VideoBackground") else {
                        return nil
                    }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                } else if type == "location" {
                    let coordinates = content.components(separatedBy: ",")
                    if let latitude = Double(coordinates[1]), let longitude = Double(coordinates[0]) {
                        let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: CGSize(width: 300, height: 300))
                        kind = .location(location)
                    }
                } else if type == "audio" {
                    guard let url = URL(string: content), let duration = dictionary["duration"] as? Float else {
                        return nil
                    }
                    audio = Audio(url: url, duration: duration, size: CGSize(width: 250, height: 50))
                    kind = .audio(audio!)
                }
                
                guard let kindMessage = kind else {
                    return nil
                }
                
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                if type == "audio" {
                    return Message(sender: sender, messageId: messageID, sentDate: sentDate, kind: kindMessage, audioDuration: audio?.duration)
                } else {
                    return Message(sender: sender, messageId: messageID, sentDate: sentDate, kind: kindMessage)
                }
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
            
            var newMessage: [String: Any] = [
                "id": conversationID,
                "type": message.kind.messageKindString,
                "name": userName,
                "content": message.kind.messageContent!,
                "date": ChatViewController.dateFormatter.string(from: message.sentDate),
                "sender_email": safeEmail,
                "is_read": false
            ]
            
            if let duration = message.audioDuration {
                newMessage["duration"] = duration
            }
            
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
                  let type = message["type"] as? String,
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
                    "type": type,
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
    
    public func deleteConversation(with conversationID: String, completion: @escaping (Bool) -> (Void)) {
        if let email = UserDefaults.standard.value(forKey: K.Database.emailAddress) as? String {
            let safeEmail = ChatUser.getSafeEmail(with: email)
            
            database.child("\(safeEmail)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let strongSelf = self else {
                    return
                }
                guard var value = snapshot.value as? [[String: Any]] else {
                    completion(false)
                    return
                }
                
                var conversationIndex = 0
                for conversation in value {
                    if conversation["id"] as? String == conversationID {
                        break
                    }
                    conversationIndex += 1
                }
                
                value.remove(at: conversationIndex)
                
                strongSelf.database.child("\(safeEmail)/conversations").setValue(value) { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    completion(true)
                }
            }
        }
    }
}
