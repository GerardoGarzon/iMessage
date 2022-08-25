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

class ProfileViewController: UIViewController {
    private let progressSpinner = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var profileConfigurations: UITableView!
    private let data = ["Log Out"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileConfigurations.register(UITableViewCell.self, forCellReuseIdentifier: K.ProfileView.TableView.cellIdentifier)
        profileConfigurations.dataSource = self
        profileConfigurations.delegate = self
    }
}

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
        self.progressSpinner.show(in: view)
        
        let firebaseAuth = Auth.auth()
        
        
        
        do {
            try firebaseAuth.signOut()
            let loginViewController = LoginViewController()
            let navigationController = UINavigationController(rootViewController: loginViewController)
            navigationController.modalPresentationStyle = .fullScreen
            
            DispatchQueue.main.async {
                self.progressSpinner.dismiss()
            }
            
            present(navigationController, animated: false)
            
        } catch let signOutError as NSError {
            print(signOutError)
        }
    }
}
