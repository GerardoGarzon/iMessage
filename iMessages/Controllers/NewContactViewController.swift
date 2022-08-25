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
        label.isHidden = true
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

extension NewContactViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        //
    }
}
