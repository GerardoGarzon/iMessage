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
    public var conversationID: String
    private var messages = [Message]()
    public var isNewChat = false
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    private let selfSender: Sender? = {
        guard let email = UserDefaults.standard.value(forKey: K.Database.emailAddress) as? String, let displayedName = UserDefaults.standard.value(forKey: K.Database.displayedName) as? String else {
            return nil
        }
        
        let safeEmail = ChatUser.getSafeEmail(with: email)
        return Sender(photoURL: "",
                      senderId: safeEmail,
                      displayName: displayedName)
    }()
    
    init(with email: String, conversationID: String?) {
        self.receiverEmailUser = email
        self.conversationID = conversationID ?? ""
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
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if self.conversationID != "" {
            listenForMessages(shouldScrollToBottom: true)
        }
    }
    
    func listenForMessages(shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForChar(with: self.conversationID) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                
                strongSelf.messages = messages
                DispatchQueue.main.async {
                    strongSelf.messagesCollectionView.reloadDataAndKeepOffset()
                    strongSelf.messagesCollectionView.scrollToLastItem(animated: false)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
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
            DatabaseManager.shared.createNewChatWith(with: self.receiverEmailUser, name: self.title ?? "User", firstMessage: message, completion: { [weak self] success, id in
                guard let strongSelf = self else {
                    return
                }
                if success {
                    DispatchQueue.main.async {
                        strongSelf.conversationID = id
                        strongSelf.listenForMessages(shouldScrollToBottom: true)
                    }
                } else {
                    print("Error")
                }
            })
            self.isNewChat = false
        } else {
            DatabaseManager.shared.sendMessage(with: message, to: self.conversationID, receiverEmail: self.receiverEmailUser, userName: self.title ?? "User") { success in
                if success {
                    print("Sended")
                } else {
                    print("Error")
                }
            }
        }
        self.messageInputBar.inputTextView.text = nil
    }
    
    private func createMessageID() -> String? {
        guard let currentUser = UserDefaults.standard.value(forKey: K.Database.emailAddress) as? String else {
            return nil
        }
        
        let safeEmail = ChatUser.getSafeEmail(with: currentUser)
        
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(self.receiverEmailUser)_\(safeEmail)_\(dateString)"
        
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
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
    }
    
}
