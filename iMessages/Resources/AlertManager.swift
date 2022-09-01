//
//  AlertManager.swift
//  iMessages
//
//  Created by Gerardo Garzon on 23/08/22.
//

import Foundation
import UIKit

final class AlertManager {
    static func createAlert(sender: UIViewController, title: String, body: String, style: UIAlertController.Style, options: [UIAlertAction]) {
        let alert = UIAlertController(title: title,
                                      message: body,
                                      preferredStyle: style)
        for action in options {
            alert.addAction(action)
        }
        sender.present(alert, animated: true)
    }
}
