//
//  Media.swift
//  iMessages
//
//  Created by Gerardo Garzon on 03/09/22.
//

import Foundation
import MessageKit

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}
