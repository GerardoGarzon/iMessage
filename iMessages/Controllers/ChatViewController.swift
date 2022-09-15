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
import CoreLocation

class ChatViewController: MessagesViewController {
    
    public var conversationID: String
    public var isNewChat = false
    public let receiverEmailUser: String
    private var isRecording = false
    private var messages = [Message]()
    private var audioRecorder: AVAudioRecorder!
    private var recordingSession: AVAudioSession!
    private lazy var audioController = AudioController(messageCollectionView: messagesCollectionView)
    private var audioURL: URL?
    
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioController.stopAnyOngoingPlaying()
    }
}

// MARK: - Chat input text view delegate methods

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let sender = selfSender else {
            return
        }
        
        createMessageID { messageID in
            let message = Message(sender: sender,
                                  messageId: messageID,
                                  sentDate: Date(),
                                  kind: .text(text))
            
            if self.isNewChat {
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
    }
    
    private func createMessageID(completion: @escaping (String) -> (Void)) {
        guard let currentUser = UserDefaults.standard.value(forKey: K.Database.emailAddress) as? String else {
            return
        }
        
        let safeEmail = ChatUser.getSafeEmail(with: currentUser)
        
        let dateString = Self.dateFormatter.string(from: Date())
        
        
        
        DatabaseManager.shared.conversationExist(for: self.receiverEmailUser, with: safeEmail) { result in
            var conversationID = ""
            
            switch result {
            case .failure(_):
                conversationID = "\(self.receiverEmailUser)_\(safeEmail)_\(dateString)"
            case .success(let id):
                conversationID = id.replacingOccurrences(of: "conversation_", with: "")
            }
            completion(conversationID)
        }
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
        
        setupRecorder()
        configureInputButtons()
    }
    
    func configureInputButtons() {
        attachMessages.addTarget(self, action: #selector(openAttachOptions), for: .touchUpInside)
        
        audiobutton.addTarget(self, action: #selector(recordingAudio), for: .touchUpInside)
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
        let locationViewController = LocationPickerViewController(coordinates: nil)
        locationViewController.navigationItem.largeTitleDisplayMode = .never
        locationViewController.completion = { [weak self] coordinates in
            let longitude: Double = coordinates.longitude
            let latitude: Double = coordinates.latitude
            
            self?.sendLocationMessages(longitude, latitude)
        }
        navigationController?.pushViewController(locationViewController, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        guard let sender = self.selfSender else {
            return
        }
        self.createMessageID { id in
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
    }
    
    func sendLocationMessages(_ longitude: Double, _ latitude: Double) {
        guard let sender = self.selfSender else {
            return
        }
        
        createMessageID { id in
            let message = Message(sender: sender,
                                  messageId: id,
                                  sentDate: Date(),
                                  kind: .location(Location(location: CLLocation(latitude: latitude, longitude: longitude), size: CGSize(width: 300, height: 300))))
            
            if self.isNewChat {
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
    
    @objc func recordingAudio() {
        if isRecording {
            self.isRecording = false
            self.audiobutton.image = UIImage(systemName: "mic")
            self.audiobutton.tintColor = UIColor(named: K.Colors.textColor)
            self.stopRecording(success: true)
        } else {
            self.isRecording = true
            self.audiobutton.image = UIImage(systemName: "record.circle.fill")?.withTintColor(.red)
            self.audiobutton.tintColor = UIColor(named: K.Colors.secondaryColor)
            self.startRecording()
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let imageURL = message.kind.messageContent, let url = URL(string: imageURL) else {
            return
        }
        
        if message.kind.messageKindString == "photo" {
            StorageManager.shared.downloadImage(from: url) { result in
                switch result {
                case .success(let data):
                    DispatchQueue.main.async {
                        let image = UIImage(data: data)
                        imageView.image = image
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        } else if message.kind.messageKindString == "video" {
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
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    func didTapPlayButton(in cell: AudioMessageCell) {
        guard
            let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) as? Message
        else {
            print("Failed to identify message when audio cell receive tap gesture")
            return
        }
        guard self.audioController.state != .stopped else {
            // There is no audio sound playing - prepare to start playing for given audio message
            self.audioController.playSound(for: message, in: cell)
            return
        }
        if self.audioController.playingMessage?.messageId == message.messageId {
            // tap occur in the current cell that is playing audio sound
            if self.audioController.state == .playing {
                self.audioController.pauseSound(for: message, in: cell)
            } else {
                self.audioController.resumeSound()
            }
        } else {
            // tap occur in a difference cell that the one is currently playing sound. First stop currently playing and start the sound for given message
            self.audioController.stopAnyOngoingPlaying()
            self.audioController.playSound(for: message, in: cell)
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

// MARK: - Audio recorder

extension ChatViewController: AVAudioRecorderDelegate {
    
    func setupRecorder() {
        self.recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try self.recordingSession.setCategory(.record, mode: .default)
            try self.recordingSession.setActive(true)
            self.recordingSession.requestRecordPermission() { allowed in return}
        } catch {
            // failed to record!
        }
    }
    
    func startRecording() {
        self.audioURL = self.getDocumentsDirectory().appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            self.audioRecorder = try AVAudioRecorder(url: self.audioURL!, settings: settings)
            self.audioRecorder.delegate = self
            self.audioRecorder.record()
            
        } catch {
            self.stopRecording(success: false)
        }
    }
    
    func stopRecording(success: Bool) {
        self.audioRecorder.stop()
        self.audioRecorder = nil
        
        let audioAsset = AVURLAsset.init(url: self.audioURL!, options: nil)
        let duration = audioAsset.duration
        let durationInSeconds = Float(CMTimeGetSeconds(duration))
        
        
        if success {
            guard let sender = self.selfSender else {
                return
            }
            
            self.createMessageID { [weak self] id in
                guard let strongSelf = self else {
                    return
                }
                let fileName = "audio_message_\(id)"
                StorageManager.shared.uploadMessageAudio(with: strongSelf.audioURL!, fileName: fileName) { result in
                    switch result {
                    case .success(let urlString):
                        // Send message
                        guard let url = URL(string: urlString) else {
                            return
                        }
                        
                        let audio = Audio(url: url, duration: durationInSeconds, size: .zero)
                        let message = Message(sender: sender, messageId: id, sentDate: Date(), kind: .audio(audio), audioDuration: durationInSeconds)
                        
                        if strongSelf.isNewChat {
                            DatabaseManager.shared.createNewChatWith(with: strongSelf.receiverEmailUser, name: strongSelf.title ?? "User", firstMessage: message, completion: { success, id in
                                if success {
                                    DispatchQueue.main.async {
                                        strongSelf.conversationID = id
                                        strongSelf.listenForMessages(shouldScrollToBottom: true)
                                    }
                                }
                            })
                            strongSelf.isNewChat = false
                        } else {
                            DatabaseManager.shared.sendMessage(with: message, to: strongSelf.conversationID, receiverEmail: strongSelf.receiverEmailUser, userName: strongSelf.title ?? "User") { _ in return }
                        }
                        
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopRecording(success: false)
        }
    }
}
