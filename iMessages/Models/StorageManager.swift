//
//  StorageManager.swift
//  iMessages
//
//  Created by Gerardo Garzon on 23/08/22.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> (Void)
    
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metaData, error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL(completion: { url, error  in
                guard let downloadURL = url else {
                    completion(.failure(error!))
                    return
                }
                let url = downloadURL.absoluteString
                print(url)
                completion(.success(url))
            })
        })
    }
}
