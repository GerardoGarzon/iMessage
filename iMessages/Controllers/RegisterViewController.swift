//
//  RegisterViewController.swift
//  iMessages
//
//  Created by Gerardo Garzon on 19/08/22.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    // MARK: - User interface elements
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.clipsToBounds = true
        return scroll
    }()
    
    private let imageIcon: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: K.RegisterView.userIcon)
        image.tintColor = .gray
        image.contentMode = .scaleAspectFit
        image.layer.masksToBounds = true
        image.layer.borderWidth = 1
        image.layer.borderColor = UIColor.gray.cgColor
        return image
    }()
    
    private let firstNameTextField: UITextField = {
        let textField = UITextField()
        textField.keyboardType = .default
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 9
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 5))
        textField.leftViewMode = .always
        textField.placeholder = K.RegisterView.firstNamePlaceHolder
        return textField
    }()
    
    private let lastNameTextField: UITextField = {
        let textField = UITextField()
        textField.keyboardType = .default
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 9
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 5))
        textField.leftViewMode = .always
        textField.placeholder = K.RegisterView.lastNamePlaceHolder
        return textField
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
        textField.placeholder = K.RegisterView.emailPlaceHolder
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
        textField.placeholder = K.RegisterView.passwordPlaceHolder
        textField.enablePasswordToggle()
        return textField
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle(K.RegisterView.registerButton, for: .normal)
        button.backgroundColor = UIColor(named: K.Colors.secondaryColor)
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 9
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    // MARK: - Added subviews
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        // Navigation bar items
        self.title = K.RegisterView.title
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageIcon)
        scrollView.addSubview(firstNameTextField)
        scrollView.addSubview(lastNameTextField)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(registerButton)
        
        // Add actions
        registerButton.addTarget(self, action: #selector(didTapRegister), for: .touchUpInside)
        
        // Add delegates
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        // Add gestures
        let chooseProfilePictureGesture = UITapGestureRecognizer(target: self, action: #selector(didTapAvatar))
        imageIcon.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        imageIcon.addGestureRecognizer(chooseProfilePictureGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        
        let size = scrollView.width / 3
        imageIcon.frame = CGRect(x: (scrollView.width - size) / 2,
                                 y: 20,
                                 width: size,
                                 height: size)
        
        imageIcon.layer.cornerRadius = imageIcon.width / 2
        
        firstNameTextField.frame = CGRect(x: 30,
                                          y: imageIcon.bottom + 20,
                                          width: scrollView.right - 60,
                                          height: 50)
        
        lastNameTextField.frame = CGRect(x: 30,
                                         y: firstNameTextField.bottom + 20,
                                         width: scrollView.right - 60,
                                         height: 50)
        
        emailTextField.frame = CGRect(x: 30,
                                      y: lastNameTextField.bottom + 20,
                                      width: scrollView.right - 60,
                                      height: 50)
        
        passwordTextField.frame = CGRect(x: 30,
                                         y: emailTextField.bottom + 20,
                                         width: scrollView.right - 60,
                                         height: 50)
        
        registerButton.frame = CGRect(x: 30,
                                      y: passwordTextField.bottom + 20,
                                      width: scrollView.right - 60,
                                      height: 50)
    }
    
    // MARK: - Tap actions
    
    @objc private func didTapAvatar() {
        presentPhotoActionSheet()
    }
    
    @objc private func didTapRegister() {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        guard let firstName = firstNameTextField.text, let lastName = lastNameTextField.text, let email = emailTextField.text, let password = passwordTextField.text, password.count >= 6 else {
            createAlertErrorRegister()
            return
        }
        
        registerNewUser(email, password, firstName, lastName)
    }
}

// MARK: - Text field delegate extension

extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameTextField {
            lastNameTextField.becomeFirstResponder()
        } else if textField == lastNameTextField {
            emailTextField.becomeFirstResponder()
        } else if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            didTapRegister()
        }
        return true
    }
}

// MARK: - Profile picture delegate extension

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
        AlertManager.createAlert(sender: self,
                                 title: K.RegisterView.ProfilePicture.title,
                                 body: K.RegisterView.ProfilePicture.subtitle,
                                 style: .actionSheet,
                                 options: [UIAlertAction(title: K.RegisterView.ProfilePicture.cancelButton,
                                                         style: .cancel,
                                                         handler: nil),
                                           UIAlertAction(title: K.RegisterView.ProfilePicture.cameraButton,
                                                         style: .default,
                                                         handler: { [weak self]_ in self?.presentCamera() }),
                                           UIAlertAction(title: K.RegisterView.ProfilePicture.galleryButton,
                                                         style: .default,
                                                         handler: { [weak self]_ in self?.presentGallery() })])
    }
    
    func presentCamera() {
        let cameraViewController = UIImagePickerController()
        cameraViewController.sourceType = .camera
        cameraViewController.delegate = self
        cameraViewController.allowsEditing = true
        present(cameraViewController, animated: true)
    }
    
    func presentGallery() {
        let galleryViewController = UIImagePickerController()
        galleryViewController.sourceType = .photoLibrary
        galleryViewController.delegate = self
        galleryViewController.allowsEditing = true
        present(galleryViewController, animated: true)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        print(info)
        let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        self.imageIcon.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Authentication extension

extension RegisterViewController {
    func createAlertErrorRegister() {
        AlertManager.createAlert(sender: self,
                                 title: K.RegisterView.RegisterAlert.title,
                                 body: K.RegisterView.RegisterAlert.body,
                                 style: .alert,
                                 options: [
                                    UIAlertAction(title: K.RegisterView.RegisterAlert.action, style: .default)])
    }
    
    func registerNewUser(_ email: String, _ password: String, _ firstName: String, _ lastName: String) {
        self.spinner.show(in: view)
        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exist in
            guard let strongSelf = self else {
                AlertManager.createAlert(sender: self!,
                                         title: K.RegisterView.RegisterExist.title,
                                         body: K.RegisterView.RegisterExist.body,
                                         style: .alert,
                                         options: [UIAlertAction(title: K.RegisterView.RegisterExist.action, style: .default)])
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            if !exist {
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    if let err = error {
                        AlertManager.createAlert(sender: strongSelf,
                                                 title: K.RegisterView.RegisterAlert.title,
                                                 body: err.localizedDescription,
                                                 style: .alert,
                                                 options: [UIAlertAction(title: K.RegisterView.RegisterAlert.action, style: .default)])
                    } else {
                        let chatUser = ChatUser(firstName: firstName, lastName: lastName, emailAddress: email)
                        DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                            if success {
                                guard let image = strongSelf.imageIcon.image, let data = image.pngData() else {
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
                            }
                        })
                        UserDefaults.standard.set(email, forKey: K.Database.emailAddress)
                        strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                    }
                }
            }
        })
    }
}
