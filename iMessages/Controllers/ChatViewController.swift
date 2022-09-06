//
//  ChatViewController.swift
//  iMessages
//
//  Created by Gerardo Garzon on 19/08/22.
//

import AVKit
import UIKit
import MessageKit
import SDWebImage
import AVFoundation
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
        button.tintColor = UIColor(named: K.Colors.textColor)
        return button
    }()
    
    private let attachMessages: InputBarButtonItem = {
        let button = InputBarButtonItem()
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = UIColor(named: K.Colors.textColor)
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
    
    // MARK: - Initializers
    
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
        messagesCollectionView.messageCellDelegate = self
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
        sendButton.setSize(CGSize(width: 30, height: 40), animated: false)
        
        let items = [sendButton, audiobutton]
        
        messagesCollectionView.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        messageInputBar.backgroundView.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        
        messageInputBar.inputTextView.layer.cornerRadius = 10
        messageInputBar.inputTextView.backgroundColor = UIColor(named: "lightTextColor")
        
        // TODO: - Audio button funcion Record/Play
        audiobutton.setSize(CGSize(width: 30, height: 40), animated: false)
        attachMessages.setSize(CGSize(width: 30, height: 40), animated: false)
        
        messageInputBar.setStackViewItems([attachMessages], forStack: .left, animated: false)
        messageInputBar.setStackViewItems(items, forStack: .right, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 62 , animated: false)
        messageInputBar.setLeftStackViewWidthConstant(to: 31, animated: false)
        
        configureInputButtons()
    }
    
    func configureInputButtons() {
        attachMessages.addTarget(self, action: #selector(openAttachOptions), for: .touchUpInside)
    }
    
    @objc func openAttachOptions() {
        AlertManager.createAlert(sender: self,
                                 title: nil,
                                 body: nil,
                                 style: .actionSheet,
                                 options: [
                                    UIAlertAction(title: "Photo", style: .default, handler: { [weak self] action in
                                        self?.presentMediaTypeMenu(isVideo: false)
                                    }),
                                    UIAlertAction(title: "Video", style: .default, handler: { [weak self] action in
                                        self?.presentMediaTypeMenu(isVideo: true)
                                    }),
                                    UIAlertAction(title: "Location", style: .default, handler: { [weak self] action in
                                        self?.openMaps()
                                    }),
                                    UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                                 ])
    }
}

// MARK: - Other type of messages managment

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func presentMediaTypeMenu(isVideo: Bool) {
        AlertManager.createAlert(sender: self,
                                 title: nil,
                                 body: nil,
                                 style: .actionSheet,
                                 options: [
                                    UIAlertAction(title: "Camera", style: .default, handler: { [weak self] action in
                                        self?.openCamera(isVideo: isVideo)
                                    }),
                                    UIAlertAction(title: "Gallery", style: .default, handler: { [weak self] action in
                                        self?.openGallery(isVideo: isVideo)
                                    }),
                                    UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                                 ])
    }
    
    func openGallery(isVideo: Bool) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        if isVideo {
            picker.mediaTypes = ["public.movie"]
        }
        self.present(picker, animated: true)
    }
    
    func openCamera(isVideo: Bool) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        if isVideo {
            picker.mediaTypes = ["public.movie"]
        }
        self.present(picker, animated: true)
    }
    
    func openMaps() {
        
    }
    
    func recordAudio() {
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        guard let id = self.createMessageID(),
              let sender = self.selfSender else {
            return
        }
    
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_message\(id).png"
            
            StorageManager.shared.uploadMessageImage(with: imageData, fileName: fileName) { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.manageMediaTypeUploaded(isVideo: false, result: result, sender: sender, id: id)
            }
        } else if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            let fileName = "video_message_\(id).mov"
            StorageManager.shared.uploadMessageVideo(with: videoURL, fileName: fileName) { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.manageMediaTypeUploaded(isVideo: true, result: result, sender: sender, id: id)
            }
        }
    }
    
    func manageMediaTypeUploaded(isVideo: Bool, result: Result<String, Error>, sender: Sender, id: String) {
        switch result {
        case .success(let urlString):
            // Send message
            guard let url = URL(string: urlString),
                  let placeholder = UIImage(systemName: "plus") else {
                return
            }
            
            var type: MessageKind?
            let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
            
            if isVideo {
                type = .video(media)
            } else {
                type = .photo(media)
            }
            
            let message = Message(sender: sender, messageId: id, sentDate: Date(), kind: type!)
            
            if self.isNewChat {
                DatabaseManager.shared.createNewChatWith(with: self.receiverEmailUser, name: self.title ?? "User", firstMessage: message, completion: { success, id in
                    if success {
                        DispatchQueue.main.async {
                            self.conversationID = id
                            self.listenForMessages(shouldScrollToBottom: true)
                        }
                    }
                })
                self.isNewChat = false
            } else {
                DatabaseManager.shared.sendMessage(with: message, to: self.conversationID, receiverEmail: self.receiverEmailUser, userName: self.title ?? "User") { _ in return }
            }
            
        case .failure(let error):
            print(error.localizedDescription)
        }
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let imageURL = message.kind.messageContent else {
            return
        }
        
        if message.kind.messageKindString == "photo" {
            imageView.sd_setImage(with: URL(string: imageURL))
        } else if message.kind.messageKindString == "video" {
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
    }
}

// MARK: - Message cell delegate

extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            
            let photoViewController = PhotoViewerViewController(with: imageURL)
            
            self.navigationController?.pushViewController(photoViewController, animated: true)
        case .video(let media):
            guard let videoURL = media.url else {
                return
            }
            let videoPlayerViewController = AVPlayerViewController()
            videoPlayerViewController.player = AVPlayer(url: videoURL)
            videoPlayerViewController.player?.play()
            present(videoPlayerViewController, animated: true)
            
        default:
            break
        }
    }
}
