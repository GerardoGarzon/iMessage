//
//  ContactTableViewCell.swift
//  iMessages
//
//  Created by Gerardo Garzon on 29/08/22.
//

import UIKit

class ContactTableViewCell: UITableViewCell {
    
    static let identifier = K.ContactsView.TableView.cellIdentifier
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 35
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userName: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(named: K.Colors.textColor)
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    private let userMessage: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(userImageView)
        contentView.addSubview(userName)
        contentView.addSubview(userMessage)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 70,
                                     height: 70)
        userName.frame = CGRect(x: userImageView.right + 15,
                                y: userImageView.top,
                                width: contentView.width - userImageView.width - 45,
                                height: userImageView.height / 3)
        userMessage.frame = CGRect(x: userImageView.right + 15,
                                   y: userName.bottom,
                                   width: contentView.width - userImageView.width - 45,
                                   height: (userImageView.height * 2) / 3)
        
        
    }
    
    public func configure(with model: Contact) {
        self.userName.text = model.name
        if model.lastMessage.type == "text" {
            self.userMessage.text = model.lastMessage.text
        } else if model.lastMessage.type == "photo" {
            self.userMessage.textAlignment = .left
            self.userMessage.attributedText = placeholderForChar(iconName: "photo", placeholder: "Photo")
        } else if model.lastMessage.type == "video" {
            self.userMessage.textAlignment = .left
            self.userMessage.attributedText = placeholderForChar(iconName: "film", placeholder: "Video")
        } else if model.lastMessage.type == "location" {
            self.userMessage.textAlignment = .left
            self.userMessage.attributedText = placeholderForChar(iconName: "map", placeholder: "Location")
        } else if model.lastMessage.type == "audio" {
            self.userMessage.textAlignment = .left
            self.userMessage.attributedText = placeholderForChar(iconName: "headphones", placeholder: "Audio")
        }
        
        if self.userImageView.image == nil {
            self.userImageView.image = UIImage(systemName: K.RegisterView.userIcon)
            self.userImageView.tintColor = .gray
        }
        self.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        
        let imagePath = "images/\(model.userEmail)_profile_picture.png"
        
        StorageManager.shared.getDownloadURL(for: imagePath) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let url):
                StorageManager.shared.downloadImage(from: url) { result in
                    switch result {
                    case .success(let data):
                        DispatchQueue.main.async {
                            let image = UIImage(data: data)
                            strongSelf.userImageView.image = image
                        }
                    case .failure(_):
                        DispatchQueue.main.async {
                            let image = UIImage(systemName: K.RegisterView.userIcon)
                            strongSelf.userImageView.image = image
                        }
                    }
                }
            case .failure(let err):
                print(err.localizedDescription)
            }
        }
    }
    
    func placeholderForChar(iconName: String, placeholder: String) -> NSMutableAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(systemName: iconName)?.withTintColor(.gray)
        let imageOffsetY: CGFloat = -3.0
        imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: imageAttachment.image!.size.width, height: imageAttachment.image!.size.height)
        let attachmentString = NSAttributedString(attachment: imageAttachment)
        let completeText = NSMutableAttributedString(string: "")
        completeText.append(attachmentString)
        let textAfterIcon = NSAttributedString(string: "  \(placeholder)")
        completeText.append(textAfterIcon)
        
        return completeText
    }
}
