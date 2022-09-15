//
//  NewContactViewCell.swift
//  iMessages
//
//  Created by Gerardo Garzon on 31/08/22.
//

import UIKit

class NewContactViewCell: UITableViewCell {
    
    static let identifier = K.ContactsView.NewContact.cellIdentifier
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userName: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = UIColor(named: K.Colors.textColor)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(userImageView)
        contentView.addSubview(userName)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 40,
                                     height: 40)
        userName.frame = CGRect(x: userImageView.right + 15,
                                y: userImageView.top,
                                width: contentView.width - userImageView.width - 10,
                                height: userImageView.height)
    }
    
    public func configure(email: String, displayedName: String) {
        self.userName.text = displayedName
        self.userImageView.image = UIImage(systemName: K.RegisterView.userIcon)
        self.userImageView.tintColor = .secondaryLabel
        self.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        
        let imagePath = "images/\(email)_profile_picture.png"
        
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
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            case .failure(let err):
                print(err.localizedDescription)
            }
        }
    }
}
