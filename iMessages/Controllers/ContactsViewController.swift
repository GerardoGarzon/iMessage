//
//  ViewController.swift
//  iMessages
//
//  Created by Gerardo Garzon on 19/08/22.
//

import UIKit
import FirebaseAuth

class ContactsViewController: UIViewController {
    
    //MARK: - User interface elements
    
    private let contactsTable: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: K.ContactsView.TableView.cellIdentifier)
        //table.isHidden = true
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
        
        view.backgroundColor = .white
        view.addSubview(contactsTable)
        view.addSubview(labelNoConversations)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        validateAuth()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        contactsTable.frame = view.bounds
        labelNoConversations.frame = view.bounds
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
            print("Created")
            let chatView = ChatViewController(with: email)
            chatView.isNewChat = true
            chatView.title = userName
            chatView.navigationItem.largeTitleDisplayMode = .never
            self.navigationController?.pushViewController(chatView, animated: true)
        }
    }
}

// MARK: - UITable delegate and data source implementation

extension ContactsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.ContactsView.TableView.cellIdentifier, for: indexPath)
        cell.textLabel?.text = "Hello!"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chatView = ChatViewController(with: "")
        chatView.title = "Gerardo Garzon"
        chatView.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(chatView, animated: true)
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
