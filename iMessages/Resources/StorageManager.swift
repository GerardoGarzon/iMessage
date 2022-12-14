//
//  StorageManager.swift
//  iMessages
//
//  Created by Gerardo Garzon on 23/08/22.
//

import Foundation
import FirebaseStorage
import AVFoundation

final class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> (Void)
    
    private let cache = NSCache<NSString, NSData>()
    
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
    
    public func getDownloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> (Void)) {
        storage.child(path).downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(error!))
                return
            }
            completion(.success(url))
        })
    }
    
    public func uploadMessageImage(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { metaData, error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            
            self.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error  in
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
    
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping UploadPictureCompletion) {
        do {
            let data = try Data(contentsOf: fileUrl)
            print(data)
            if let storageDate = data as Data? {
                let metaData = StorageMetadata()
                metaData.contentType = "video/mp4"
                storage.child("message_videos/\(fileName)").putData(storageDate, metadata: metaData, completion: { [weak self] metadata, error in
                    guard error == nil else {
                        // failed
                        print("failed to upload video file to firebase for picture")
                        completion(.failure(error!))
                        return
                    }
                    
                    self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
                        guard let url = url else {
                            print("Failed to get download url")
                            completion(.failure(error!))
                            return
                        }
                        
                        let urlString = url.absoluteString
                        print("download url returned: \(urlString)")
                        completion(.success(urlString))
                    })
                })
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    public func uploadMessageAudio(with fileURL: URL, fileName: String, completion: @escaping UploadPictureCompletion) {
        do {
            let data = try Data(contentsOf: fileURL)
            print(data)
            if let storageDate = data as Data? {
                let metaData = StorageMetadata()
                metaData.contentType = "audio/mpeg"
                storage.child("message_audio/\(fileName)").putData(storageDate, metadata: metaData, completion: { [weak self] metadata, error in
                    guard error == nil else {
                        // failed
                        print("failed to upload audio file to firebase for picture")
                        completion(.failure(error!))
                        return
                    }
                    
                    self?.storage.child("message_audio/\(fileName)").downloadURL(completion: { url, error in
                        guard let url = url else {
                            print("Failed to get download url")
                            completion(.failure(error!))
                            return
                        }
                        
                        let urlString = url.absoluteString
                        print("download url returned: \(urlString)")
                        completion(.success(urlString))
                    })
                })
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    public func downloadImage(from url: URL, completion: @escaping (Result<Data, Error>) -> (Void) ) {
        let urlString = "\(url)"
        
        if let image = cache.object(forKey: urlString as NSString) as? Data {
            print("Cache")
            completion(.success(image))
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            print("Request")
            guard let data = data, error == nil else {
                completion(.failure(CustomError.errorDownloadingImage))
                return
            }
            self?.cache.setObject(NSData(data: data), forKey: urlString as NSString)
            completion(.success(data))
        }.resume()
    }
}

enum CustomError: Error {
    case errorDownloadingImage
}
