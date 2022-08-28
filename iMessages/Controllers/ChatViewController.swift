//
//  ChatViewController.swift
//  iMessages
//
//  Created by Gerardo Garzon on 19/08/22.
//

import UIKit
import MessageKit
import InputBarAccessoryView

class ChatViewController: MessagesViewController {
    public let receiverEmailUser: String
    public var isNewChat = false
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.timeZone = .current
        return formatter
    }()
    
    private var messages = [Message]()
    private let selfSender: Sender? = {
        
        guard let email = UserDefaults.standard.value(forKey: K.Database.emailAddress) else {
            return nil
        }
        
        return Sender(photoURL: "",
                      senderId: email as! String,
                      displayName: "Gerardo Gonzalez")
        
    }()
    
    init(with email: String) {
        self.receiverEmailUser = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let sender = selfSender, let messageID = createMessageID() else {
            return
        }
        
        let message = Message(sender: sender,
                              messageId: messageID,
                              sentDate: Date(),
                              kind: .text(text))
        
        if isNewChat {
            DatabaseManager.shared.createNewChatWith(with: self.receiverEmailUser, firstMessage: message, completion: { [weak self] success in
                guard let strongSelf = self else {
                    return
                }
                if success {
                    print("Sended")
                } else {
                    print("Error")
                }
            })
        }
    }
    
    private func createMessageID() -> String? {
        guard let currentUser = UserDefaults.standard.value(forKey: K.Database.emailAddress) else {
            return nil
        }
        
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(self.receiverEmailUser)_\(currentUser)_\(dateString)"
        
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        } else {
            return Sender(photoURL: "", senderId: "-1", displayName: "")
        }
        
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
