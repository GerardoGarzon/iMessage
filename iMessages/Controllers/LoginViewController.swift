//
//  LoginViewController.swift
//  iMessages
//
//  Created by Gerardo Garzon on 19/08/22.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import GoogleSignIn
import FBSDKLoginKit
import FirebaseCore

class LoginViewController: UIViewController {
    // MARK: - User interface elements
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var loginObserver: NSObjectProtocol?
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.clipsToBounds = true
        return scroll
    }()
    
    private let imageIcon: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: K.appLogo)
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.keyboardType = .emailAddress
        textField.textContentType = .emailAddress
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 9
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 5))
        textField.leftViewMode = .always
        textField.placeholder = K.LoginView.emailPlaceHolder
        textField.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        textField.tintColor = UIColor(named: K.Colors.textColor)
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.keyboardType = .default
        textField.textContentType = .password
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.returnKeyType = .done
        textField.isSecureTextEntry = true
        textField.layer.cornerRadius = 9
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 5))
        textField.leftViewMode = .always
        textField.placeholder = K.LoginView.passwordPlaceHolder
        textField.enablePasswordToggle()
        textField.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        textField.tintColor = UIColor(named: K.Colors.textColor)
        return textField
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle(K.LoginView.loginButton, for: .normal)
        button.backgroundColor = UIColor(named: K.Colors.secondaryColor)
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 9
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        return button
    }()
    
    private let facebookSingInButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = [K.LoginView.FacebookLogin.profilePermission, K.LoginView.FacebookLogin.emailPermission]
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 9
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        return button
    }()
    
    private let googleSingInButton: GIDSignInButton = {
        let button = GIDSignInButton()
        button.style = .wide
        button.colorScheme = .light
        return button
    }()
    
    // MARK: - Added subviews
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.selectedIndex = 0
        
        UserDefaults.standard.removeObject(forKey: K.Database.emailAddress)
        UserDefaults.standard.removeObject(forKey: K.Database.displayedName)
        
        view.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        
        // Navigation bar items
        self.title = K.LoginView.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: K.LoginView.registerButton,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageIcon)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookSingInButton)
        scrollView.addSubview(googleSingInButton)
        
        // Add actions and delegates
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        googleSingInButton.addTarget(self, action: #selector(googleDidTapSingIn), for: .touchUpInside)
        emailTextField.delegate = self
        passwordTextField.delegate = self
        facebookSingInButton.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        
        let size = scrollView.width / 3
        imageIcon.frame = CGRect(x: (scrollView.width - size) / 2,
                                 y: 20,
                                 width: size,
                                 height: size)
        emailTextField.frame = CGRect(x: 30,
                                      y: imageIcon.bottom + 20,
                                      width: scrollView.right - 60,
                                      height: 50)
        passwordTextField.frame = CGRect(x: 30,
                                         y: emailTextField.bottom + 20,
                                         width: scrollView.right - 60,
                                         height: 50)
        loginButton.frame = CGRect(x: 30,
                                   y: passwordTextField.bottom + 20,
                                   width: scrollView.right - 60,
                                   height: 50)
        facebookSingInButton.frame = CGRect(x: 30,
                                            y: loginButton.bottom + 20,
                                            width: scrollView.right - 60,
                                            height: 50)
        googleSingInButton.frame = CGRect(x: 30,
                                          y: facebookSingInButton.bottom + 20,
                                          width: scrollView.right - 60,
                                          height: 50)
        
    }
    
    // MARK: - Tap actions
    
    @objc private func didTapRegister() {
        let registerViewController = RegisterViewController()
        registerViewController.title = K.RegisterView.title
        navigationController?.pushViewController(registerViewController, animated: true)
    }
    
    @objc private func didTapLogin() {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        guard let email = emailTextField.text, let password = passwordTextField.text, password.count >= 6 else {
            createAlertErrorLogin()
            return
        }
        
        loginUser(email, password)
    }
    
    public static func createLoginObserver() {
        NotificationCenter.default.post(name: .didLoginInNotification, object: nil)
    }
}

// MARK: - Text field delegate extension

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            didTapLogin()
        }
        return true
    }
}

// MARK: - Authentication extensions

extension LoginViewController {
    func createAlertErrorLogin() {
        AlertManager.createAlert(sender: self,
                                 title: K.LoginView.LoginAlert.title,
                                 body: K.LoginView.LoginAlert.body,
                                 style: .alert,
                                 options: [UIAlertAction(title: K.LoginView.LoginAlert.action, style: .default)])
    }
    
    func loginUser(_ email: String, _ password: String) {
        self.spinner.show(in: view)
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            if let err = error {
                AlertManager.createAlert(
                    sender: strongSelf,
                    title: K.RegisterView.RegisterAlert.title,
                    body: err.localizedDescription,
                    style: .alert,
                    options: [UIAlertAction(title: K.RegisterView.RegisterAlert.action, style: .default)])
            } else {
                DatabaseManager.shared.getUserInfo(with: email) { result in
                    switch result {
                    case .success(let info):
                        if let firstName = info["first_name"], let lastName = info["last_name"] {
                            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: K.Database.displayedName)
                            UserDefaults.standard.set(email, forKey: K.Database.emailAddress)
                            LoginViewController.createLoginObserver()
                            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}


// MARK: - Google login delegate

extension LoginViewController {
    @objc func googleDidTapSingIn() {
        self.spinner.show(in: view)
        // Google singin configuration
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [weak self] user, error in
            
            guard let strongSelf = self else {
                return
            }
            
            if let error = error {
                AlertManager.createAlert(sender: strongSelf,
                                         title: K.LoginView.GoogleLogin.titleError,
                                         body: error.localizedDescription,
                                         style: .alert,
                                         options: [UIAlertAction(title: K.LoginView.LoginAlert.action, style: .default)])
                return
            }
            
            guard let authentication = user?.authentication,
                  let idToken = authentication.idToken else {
                return
            }
            
            guard let user = user else {
                return
            }
            
            guard let email = user.profile?.email,
                  let firstName = user.profile?.givenName,
                  let lastName = user.profile?.familyName else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
            
            UserDefaults.standard.set(email, forKey: K.Database.emailAddress)
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: K.Database.displayedName)
            
            strongSelf.createGoogleUser(with: credential, email, firstName, lastName, user)
        }
    }
    
    func createGoogleUser(with credential: AuthCredential, _ email: String, _ firstName: String, _ lastName: String, _ user: GIDGoogleUser) {
        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exist in
            guard let strongSelf = self else {
                DispatchQueue.main.async {
                    self!.spinner.dismiss()
                }
                return
            }
            
            Auth.auth().signIn(with: credential, completion: { authResult, error in
                if let err = error {
                    AlertManager.createAlert(sender: strongSelf,
                                             title: K.LoginView.GoogleLogin.titleError,
                                             body: err.localizedDescription,
                                             style: .alert,
                                             options: [UIAlertAction(title: K.LoginView.LoginAlert.action, style: .default)])
                    DispatchQueue.main.async {
                        strongSelf.spinner.dismiss()
                    }
                    return
                }
                
                if !exist {
                    let chatUser = ChatUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            if ((user.profile?.hasImage) != nil) {
                                guard let downloadURL = user.profile?.imageURL(withDimension: 200) else {
                                    DispatchQueue.main.async {
                                        strongSelf.spinner.dismiss()
                                    }
                                    return
                                }
                                
                                URLSession.shared.dataTask(with: downloadURL, completionHandler: { data, response, error in
                                    guard let data = data else {
                                        DispatchQueue.main.async {
                                            strongSelf.spinner.dismiss()
                                        }
                                        return
                                    }
                                    
                                    if let err = error {
                                        print(err.localizedDescription)
                                        DispatchQueue.main.async {
                                            strongSelf.spinner.dismiss()
                                        }
                                        return
                                    }
                                    
                                    let fileName = chatUser.profilePicture
                                    StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                        switch result {
                                        case .success(let dowloadURL):
                                            UserDefaults.standard.set(dowloadURL, forKey: "URL")
                                            print(dowloadURL)
                                        case .failure(let error):
                                            print(error)
                                        }
                                    })
                                }).resume()
                            }
                        }
                    })
                }
                
                DispatchQueue.main.async {
                    strongSelf.spinner.dismiss()
                }
                LoginViewController.createLoginObserver()
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }
}

// MARK: - Facebook login delegate

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        self.spinner.show(in: view)
        guard let token = result?.token?.tokenString else {
            self.facebookError()
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        facebookRequest.start(completion: { _, result, error in
            guard let result = result as? [String: Any], error == nil else {
                self.facebookError()
                return
            }
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let picturePath = result["picture"] as? [String: Any?],
                  let data = picturePath["data"] as? [String: Any?],
                  let downloadURL = data["url"] as? String,
                  let email = result["email"] as? String else {
                self.facebookError()
                return
            }
            UserDefaults.standard.set(email, forKey: K.Database.emailAddress)
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: K.Database.displayedName)
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            self.createFacebookUser(with: credential, email, firstName, lastName, downloadURL)
        })
    }
    
    func createFacebookUser(with credential: AuthCredential, _ email: String, _ firstName: String, _ lastName: String, _ downloadURL: String) {
        
        DatabaseManager.shared.userExists(with: email, completion: { exist in
            Auth.auth().signIn(with: credential, completion: { [weak self] authResult, error in
                guard let strongSelf = self else {
                    DispatchQueue.main.async {
                        self!.spinner.dismiss()
                    }
                    return
                }
                
                if error != nil {
                    strongSelf.facebookError()
                    return
                }
                
                
                if !exist {
                    let chatUser = ChatUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            URLSession.shared.dataTask(with: URL(string: downloadURL)!, completionHandler: { data, response, error in
                                guard let data = data else {
                                    DispatchQueue.main.async {
                                        strongSelf.spinner.dismiss()
                                    }
                                    return
                                }
                                
                                if let err = error {
                                    print(err.localizedDescription)
                                    DispatchQueue.main.async {
                                        strongSelf.spinner.dismiss()
                                    }
                                    return
                                }
                                
                                let fileName = chatUser.profilePicture
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                    switch result {
                                    case .success(let dowloadURL):
                                        UserDefaults.standard.set(dowloadURL, forKey: "URL")
                                        print(dowloadURL)
                                    case .failure(let error):
                                        print(error)
                                    }
                                })
                            }).resume()
                        }
                    })
                }
                
                DispatchQueue.main.async {
                    strongSelf.spinner.dismiss()
                }
                LoginViewController.createLoginObserver()
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }
    
    func facebookError() {
        AlertManager.createAlert(sender: self,
                                 title: K.LoginView.FacebookLogin.titleError,
                                 body: K.LoginView.FacebookLogin.bodyError,
                                 style: .alert,
                                 options: [UIAlertAction(title: K.LoginView.LoginAlert.action, style: .default)])
        DispatchQueue.main.async {
            self.spinner.dismiss()
        }
    }
}
