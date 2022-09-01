//
//  Constants.swift
//  iMessages
//
//  Created by Gerardo Garzon on 20/08/22.
//

struct K {
    static let appLogo = "AppLogo"
    struct LoginView {
        static let title = "Login"
        static let emailPlaceHolder = "Email Address"
        static let passwordPlaceHolder = "Password"
        static let loginButton = "Login"
        static let registerButton = "Register"
        struct LoginAlert {
            static let title = "Error"
            static let body = "Credentials are wrong or incomplete"
            static let action = "OK"
        }
        struct OtherLogin {
            static let orLabel = "OR"
        }
        struct FacebookLogin {
            static let titleError = "Facebook error"
            static let bodyError = "User failed to log in with Facebook"
            static let profilePermission = "public_profile"
            static let emailPermission = "email"
        }
        struct GoogleLogin {
            static let titleError = "Google error"
            static let bodyError = "User failed to log in with Google"
        }
    }
    
    struct RegisterView {
        static let userIcon = "person.circle.fill"
        static let title = "Create Account"
        static let firstNamePlaceHolder = "First Name"
        static let lastNamePlaceHolder = "Last Name"
        static let emailPlaceHolder = "Email Address"
        static let passwordPlaceHolder = "Password"
        static let registerButton = "Register"
        struct RegisterAlert {
            static let title = "Error"
            static let body = "Information are incomplete"
            static let action = "OK"
        }
        struct ProfilePicture {
            static let title = "Profile picture"
            static let subtitle = "Select an option to choose your profile picture"
            static let cancelButton = "Cancel"
            static let cameraButton = "Take a photo"
            static let galleryButton = "Choose a photo"
        }
        struct RegisterExist {
            static let title = "Error"
            static let body = "User already exist"
            static let action = "OK"
        }
    }
    
    struct ContactsView {
        static let title = "iMessage"
        static let noConversations = "There are no conversations."
        struct LogOut {
            static let title = "Log out"
            static let body = "Are you sure you want to logout?"
            static let cancelButton = "Cancel"
            static let continueButton = "Continue"
        }
        struct TableView {
            static let cellIdentifier = "messageCell"
        }
        struct NewContact {
            static let cellIdentifier = "chatCell"
            static let newContactPlaceHolder = "Find a friend"
            static let cancelButtonSearch = "Cancel"
            static let noResults = "No results"
        }
    }
    
    struct ProfileView {
        struct TableView {
            static let cellIdentifier = "profileCell"
        }
    }
    
    struct Colors {
        static let secondaryColor = "SecondaryColor"
        static let facebookColor = "FacebookColor"
        
    }
    
    struct Extensions {
        static let eyeNotSlashed = "eye.fill"
        static let eyeSlashed = "eye.slash.fill"
    }
    
    struct Database {
        static let usersChild = "users"
        static let firstName = "first_name"
        static let lastName = "last_name"
        static let emailAddress = "email_address"
        static let profilePicture = "profile_pictureURL"
        
        static let displayedName = "displayed_name"
        static let nameField = "name"
        static let emailField = "email"
    }
}
