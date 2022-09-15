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
    private var loginObserver: NSObjectProtocol?
    private var data = [String]()
    
    @IBOutlet weak var profileConfigurations: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginInNotification, object: nil, queue: .main, using: { [weak self] notification in
            guard let strongSelf = self else {
                return
            }
            strongSelf.createObserver()
            strongSelf.profileConfigurations.tableHeaderView = strongSelf.createHeader()
            strongSelf.tabBarController?.selectedIndex = 0
        })
        
        profileConfigurations.separatorStyle = .none
        profileConfigurations.register(UITableViewCell.self, forCellReuseIdentifier: K.ProfileView.TableView.cellIdentifier)
        profileConfigurations.dataSource = self
        profileConfigurations.delegate = self
        profileConfigurations.tableHeaderView = createHeader()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func createObserver() {
        UserDefaults.standard.set("login", forKey: "login")
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
                print(err.localizedDescription)
            }
        })
        
        headerView.addSubview(profileImageView)
        
        data.append("\(UserDefaults.standard.value(forKey: K.Database.displayedName) ?? "Name")")
        data.append("\(UserDefaults.standard.value(forKey: K.Database.emailAddress) ?? "Email")")
        data.append("")
        data.append("Log Out")
        profileConfigurations.reloadData()
        profileConfigurations.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        return headerView
    }
    
    func downloadProfilePicture(in imageView: UIImageView, with urlPath: URL) {
        StorageManager.shared.downloadImage(from: urlPath) { result in
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
    }
}

// MARK: - UITable view delegate

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.ProfileView.TableView.cellIdentifier, for: indexPath)
        if indexPath.row == 3 {
            cell.textLabel?.textColor = UIColor(named: K.Colors.secondaryColor)
            cell.textLabel?.font = .systemFont(ofSize: 15, weight: .regular)
        } else {
            cell.textLabel?.textColor = UIColor(named: K.Colors.textColor)
            cell.textLabel?.font = .systemFont(ofSize: 18, weight: .regular)
            cell.selectionStyle = .none
        }
        cell.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 3 {
            logOutPressed()
        }
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
            
            UserDefaults.standard.removeObject(forKey: K.Database.emailAddress)
            UserDefaults.standard.removeObject(forKey: K.Database.displayedName)
            
            self.data = []
            self.profileConfigurations.reloadData()
            
            present(navigationController, animated: true)
            
        } catch let signOutError as NSError {
            print(signOutError)
        }
    }
}
