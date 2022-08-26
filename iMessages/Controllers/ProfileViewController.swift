//
//  ProfileViewController.swift
//  iMessages
//
//  Created by Gerardo Garzon on 23/08/22.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import GoogleSignIn
import FBSDKLoginKit

class ProfileViewController: UIViewController {
    private let progressSpinner = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var profileConfigurations: UITableView!
    private let data = ["Log Out"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Enter")
        
        profileConfigurations.register(UITableViewCell.self, forCellReuseIdentifier: K.ProfileView.TableView.cellIdentifier)
        profileConfigurations.dataSource = self
        profileConfigurations.delegate = self
        profileConfigurations.tableHeaderView = createHeader()
    }
}

// MARK: - Header extension

extension ProfileViewController {
    func createHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: K.Database.emailAddress) as? String else {
            return nil
        }
        
        let safeEmail = ChatUser.getSafeEmail(with: email)
        let profilePicture = ChatUser.getProfilePictureName(with: safeEmail)
        let imagePath = "images/\(profilePicture)"
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        
        let profileImageView = UIImageView(frame: CGRect(x: (headerView.width / 2) - 125,
                                                         y: (headerView.height / 2) - 125,
                                                         width: 250,
                                                         height: 250))
        profileImageView.layer.cornerRadius = profileImageView.width / 2
        profileImageView.tintColor = .gray
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.borderColor = UIColor.gray.cgColor
        profileImageView.layer.borderWidth = 1
        profileImageView.image = UIImage(systemName: K.RegisterView.userIcon)
        profileImageView.layer.masksToBounds = true
        
        StorageManager.shared.getDownloadURL(for: imagePath, completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let url):
                strongSelf.downloadProfilePicture(in: profileImageView, with: url)
            case .failure(let err):
                print("Failed to get the profile picture: \(err.localizedDescription)")
            }
        })
        
        headerView.addSubview(profileImageView)
        return headerView
    }
    
    func downloadProfilePicture(in imageView: UIImageView, with urlPath: URL) {
        URLSession.shared.dataTask(with: urlPath, completionHandler: { data, _, error in
            guard let data = data, error == nil else {
                print("Failed to get the profile picture.")
                return
            }
            
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
        }).resume()
    }
}

// MARK: - UITable view delegate

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.ProfileView.TableView.cellIdentifier, for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .black
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        logOutPressed()
    }
}

// MARK: - Logout from firebase extension

extension ProfileViewController {
    func logOutPressed() {
        
        AlertManager.createAlert(sender: self,
                                 title: K.ContactsView.LogOut.title,
                                 body: K.ContactsView.LogOut.body,
                                 style: .alert,
                                 options: [
                                    UIAlertAction(title: K.ContactsView.LogOut.continueButton,
                                                  style: UIAlertAction.Style.destructive,
                                                  handler: singOutFromFirebase),
                                    UIAlertAction(title: K.ContactsView.LogOut.cancelButton,
                                                  style: UIAlertAction.Style.default,
                                                  handler: nil)])
    }
    
    func singOutFromFirebase(alertAction: UIAlertAction) {
        do {
            try Auth.auth().signOut()
            FBSDKLoginKit.LoginManager().logOut()
            
            let loginViewController = LoginViewController()
            let navigationController = UINavigationController(rootViewController: loginViewController)
            navigationController.modalPresentationStyle = .fullScreen
            
            UserDefaults.standard.setValue(nil, forKey: K.Database.emailAddress)
            
            present(navigationController, animated: true)
            
        } catch let signOutError as NSError {
            print(signOutError)
        }
    }
}
