//
//  ViewController.swift
//  iMessages
//
//  Created by Gerardo Garzon on 19/08/22.
//

import UIKit
import FirebaseAuth

class ContactsViewController: UIViewController {
    
    private var conversations: [Contact] = []
    private let notificationManager = NotificationManager()
    
    
    //MARK: - User interface elements
    
    private let contactsTable: UITableView = {
        let table = UITableView()
        table.register(ContactTableViewCell.self,
                       forCellReuseIdentifier: ContactTableViewCell.identifier)
        table.isHidden = true
        return table
    }()
    
    private let labelNoConversations: UILabel = {
        let label = UILabel()
        label.text = K.ContactsView.noConversations
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        contactsTable.delegate = self
        contactsTable.dataSource = self
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(didTapComposeButton))
        
        if let tabBarItem1 = self.tabBarController?.tabBar.items?[0] {
            tabBarItem1.image = UIImage(systemName: "message")
            tabBarItem1.selectedImage = UIImage(systemName: "message.fill")
        }
        if let tabBarItem2 = self.tabBarController?.tabBar.items?[1] {
            tabBarItem2.image = UIImage(systemName: "person")
            tabBarItem2.selectedImage = UIImage(systemName: "person.fill")
        }
        
        view.backgroundColor = .white
        view.addSubview(contactsTable)
        view.addSubview(labelNoConversations)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        validateAuth()
        listenForConversations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        contactsTable.frame = view.bounds
        labelNoConversations.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UserDefaults.standard.value(forKey: "login") != nil {
            self.clearData()
            self.listenForConversations()
            UserDefaults.standard.removeObject(forKey: "login")
        }
    }
    
    @objc func didTapComposeButton() {
        let contactViewController = NewContactViewController()
        
        contactViewController.completion = { result in
            self.createNewContact(with: result)
        }
        
        let newContactNavigationController = UINavigationController(rootViewController: contactViewController)
        
        present(newContactNavigationController, animated: true)
    }
    
    func createNewContact(with result: [String: String]) {
        if let email = result[K.Database.emailField], let userName = result[K.Database.nameField] {
            let chatView = ChatViewController(with: email, conversationID: nil)
            chatView.isNewChat = true
            chatView.title = userName
            chatView.navigationItem.largeTitleDisplayMode = .never
            self.navigationController?.pushViewController(chatView, animated: true)
        }
    }
    
    func listenForConversations() {
        guard let email = UserDefaults.standard.value(forKey: K.Database.emailAddress) as? String else {
            return
        }
        
        let safeEmail = ChatUser.getSafeEmail(with: email)
        DatabaseManager.shared.getAllChats(for: safeEmail, completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    return
                }
                
                strongSelf.conversations = conversations
                DispatchQueue.main.async {
                    if !strongSelf.conversations.isEmpty {
                        strongSelf.contactsTable.isHidden = false
                        strongSelf.labelNoConversations.isHidden = true
                    }
                    strongSelf.contactsTable.reloadData()
                    // TODO: Notifications are not shown with the app open
                    // strongSelf.notificationManager.createNotification(title: "Messages", body: "New Message")
                }
            case .failure(let error):
                strongSelf.contactsTable.isHidden = true
                strongSelf.labelNoConversations.isHidden = false
                print(error.localizedDescription)
            }
        })
    }
    
    func clearData() {
        self.conversations.removeAll()
        self.contactsTable.reloadData()
    }
}

// MARK: - UITable delegate and data source implementation

extension ContactsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.identifier, for: indexPath) as! ContactTableViewCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        let chatView = ChatViewController(with: model.userEmail, conversationID: model.id)
        chatView.title = model.name
        chatView.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(chatView, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}

// MARK: - User authentication validation

extension ContactsViewController {
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let loginViewController = LoginViewController()
            let navigationController = UINavigationController(rootViewController: loginViewController)
            navigationController.modalPresentationStyle = .fullScreen
            present(navigationController, animated: false)
        }
    }
    
}
