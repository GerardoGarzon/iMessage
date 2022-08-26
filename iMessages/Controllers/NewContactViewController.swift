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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: K.ContactsView.NewContact.cellIdentifier)
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
        
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: K.ContactsView.NewContact.cancelButtonSearch,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        
        searchBar.becomeFirstResponder()
        searchBar.delegate = self
        friendsTableView.delegate = self
        friendsTableView.dataSource = self
        
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
        let results: [[String: String]] = self.usersList.filter({
            guard let name = $0["name"]?.lowercased() as? String else {
                return false
            }
            return name.contains(regex.lowercased())
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
        self.isSearching = false
    }
}

// MARK: - Table view delegate

extension NewContactViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.ContactsView.NewContact.cellIdentifier, for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
    
    
}
