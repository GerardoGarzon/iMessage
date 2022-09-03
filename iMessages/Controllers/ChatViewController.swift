//
//  ChatViewController.swift
//  iMessages
//
//  Created by Gerardo Garzon on 19/08/22.
//

import UIKit
import MessageKit
import SDWebImage
import InputBarAccessoryView

class ChatViewController: MessagesViewController {
    
    public let receiverEmailUser: String
    public var conversationID: String
    private var messages = [Message]()
    public var isNewChat = false
    
    // MARK: - User interface elements
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    private let audiobutton: InputBarButtonItem = {
        let button = InputBarButtonItem()
        button.setImage(UIImage(systemName: "mic"), for: .normal)
        button.tintColor = UIColor.gray
        return button
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
    
    // MARK: - Delegates
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: K.Colors.backgroundColor)

        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messageInputBar.delegate = self
        
        configureInputTextView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if self.conversationID != "" {
            listenForMessages(shouldScrollToBottom: true)
        } else {
            guard let sender = selfSender?.senderId else {
                return
            }
            print(sender, self.receiverEmailUser)
            DatabaseManager.shared.conversationExist(for: sender, with: self.receiverEmailUser) { result in
                switch result {
                case .failure(_):
                    return
                case .success(let conversationID):
                    DispatchQueue.main.async {
                        self.conversationID = conversationID
                        self.listenForMessages(shouldScrollToBottom: true)
                    }
                }
            }
        }
    }
}

// MARK: - Chat input text view delegate methods

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
                }
            })
            self.isNewChat = false
        } else {
            DatabaseManager.shared.sendMessage(with: message, to: self.conversationID, receiverEmail: self.receiverEmailUser, userName: self.title ?? "User") { _ in return}
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
    
    func configureInputTextView() {
        let sendButton = messageInputBar.sendButton
        sendButton.title = ""
        sendButton.image = UIImage(systemName: "paperplane.fill")
        sendButton.tintColor = UIColor.gray
        sendButton.setSize(CGSize(width: 30, height: 30), animated: false)
        
        let items = [sendButton, audiobutton]
        
        messagesCollectionView.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        messageInputBar.backgroundView.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        
        audiobutton.setSize(CGSize(width: 30, height: 30), animated: false)
        
        messageInputBar.setStackViewItems(items, forStack: .right, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 62 , animated: false)
    }
}

// MARK: - Messages managment

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
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        var safeEmail = ""
        if sender.senderId == selfSender?.senderId {
            guard let currentUser = UserDefaults.standard.value(forKey: K.Database.emailAddress) as? String else {
                return
            }
            safeEmail = ChatUser.getSafeEmail(with: currentUser)
            
        } else {
            safeEmail = ChatUser.getSafeEmail(with: self.receiverEmailUser)
        }
        let imagePath = "images/\(safeEmail)_profile_picture.png"
        StorageManager.shared.getDownloadURL(for: imagePath) { result in
            switch result{
            case .success(let url):
                avatarView.sd_setImage(with: url)
            case .failure(_):
                return
            }
        }
    }
}
