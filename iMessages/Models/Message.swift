//
//  Message.swift
//  iMessages
//
//  Created by Gerardo Garzon on 23/08/22.
//

import Foundation
import MessageKit

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link"
        case .custom(_):
            return "custom"
        }
    }
    
    var messageContent: String? {
        switch self {
        case .text(let text):
            return text
        case .attributedText(_):
            return nil
        case .photo(let mediaItem):
            if let url = mediaItem.url?.absoluteString {
                return url
            } else {
                return nil
            }
        case .video(let mediaItem):
            if let url = mediaItem.url?.absoluteString {
                return url
            } else {
                return nil
            }
        case .location(_):
            return nil
        case .emoji(_):
            return nil
        case .audio(_):
            return nil
        case .contact(_):
            return nil
        case .linkPreview(_):
            return nil
        case .custom(_):
            return nil
        }
    }
}
