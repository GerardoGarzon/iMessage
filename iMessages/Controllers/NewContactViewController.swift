//
//  NewContactViewController.swift
//  iMessages
//
//  Created by Gerardo Garzon on 23/08/22.
//

import UIKit
import JGProgressHUD

class NewContactViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    public var completion: (([String: String]) -> (Void))?
    
    private var usersList = [[String: String]]()
    private var results = [[String: String]]()
    private var isSearching = false
    
    private let searchBar: UISearchBar = {
        let search = UISearchBar()
        search.placeholder = K.ContactsView.NewContact.newContactPlaceHolder
        return search
    }()
    
    private let friendsTableView: UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(NewContactViewCell.self, forCellReuseIdentifier: NewContactViewCell.identifier)
        return tableView
    }()
    
    private let noResultLabel: UILabel = {
        let label = UILabel()
        label.isHidden = false
        label.text = K.ContactsView.NewContact.noResults
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 20, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: K.ContactsView.NewContact.cancelButtonSearch,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        
        searchBar.becomeFirstResponder()
        searchBar.delegate = self
        friendsTableView.delegate = self
        friendsTableView.dataSource = self
        friendsTableView.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        
        view.addSubview(friendsTableView)
        view.addSubview(noResultLabel)
    }
    
    override func viewDidLayoutSubviews() {
        friendsTableView.frame = view.bounds
        noResultLabel.frame = view.bounds
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

// MARK: - Search friends methods

extension NewContactViewController: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismissSelf()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count >= 2 && !isSearching{
            self.spinner.show(in: view)
            isSearching = true
            
            self.searchUsers(query: searchText)
        } else if searchText.count < 2 {
            self.results = [[String: String]]()
            self.updateUI()
        }
    }
    
    func searchUsers(query: String) {
        DatabaseManager.shared.readUsersCollection(completion: { result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let users):
                self.usersList = users
                self.filterUsers(with: query)
            }
        })
    }
    
    func filterUsers(with regex: String) {
        guard let user = UserDefaults.standard.value(forKey: K.Database.emailAddress), let emailUser = user as? String else {
            return
        }
        
        let safeEmail = ChatUser.getSafeEmail(with: emailUser)
        
        let results: [[String: String]] = self.usersList.filter({
            guard let name = $0[K.Database.nameField]?.lowercased() as? String,
                  let email = $0[K.Database.emailField] else {
                return false
            }
            return name.contains(regex.lowercased()) && email != safeEmail
        })
        self.results = results
        self.updateUI()
    }
    
    func updateUI() {
        if self.results.isEmpty {
            self.noResultLabel.isHidden = false
            self.friendsTableView.isHidden = true
        } else {
            self.noResultLabel.isHidden = true
            self.friendsTableView.isHidden = false
            self.friendsTableView.reloadData()
        }
        self.spinner.dismiss()
        self.isSearching = false
        self.friendsTableView.backgroundColor = UIColor(named: K.Colors.backgroundColor)
    }
}

// MARK: - Table view delegate

extension NewContactViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NewContactViewCell.identifier, for: indexPath) as! NewContactViewCell
        
        guard let email = self.results[indexPath.row]["email"], let name = self.results[indexPath.row]["name"] else {
            return cell
        }
        cell.accessoryType = .disclosureIndicator
        cell.configure(email: email, displayedName: name)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.dismissSelf()
        if let handler = completion {
            handler(self.results[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
}
