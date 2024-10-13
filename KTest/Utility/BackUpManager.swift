//
//  BackUpManager.swift
//  KTest
//
//  Created by Md Zahidul Islam Mazumder on 10/13/24.
//

import Foundation
import Combine

class BackupManager {
    private var backupTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Define the backup interval (in seconds)
    private var backupInterval: TimeInterval
    private let chatBackupAPI = "https://messaging-dev.kotha.im/v1/message/backup"
    
    // Access Token for authentication (you might want to store this securely)
    private let accessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjVlNWUzZjYyYzEyMTg3N2RlYmU1YjY0ZCIsImlhdCI6MTcyODIzNzc3NSwiZXhwIjoxNzI4MzI0MTc1fQ.0spSclloJiWu0TAu4nDQjwvPL1Crasy-MgzbaGzr6S0"
    
    // Initialize with configurable backup interval
    init(backupInterval: TimeInterval) {
        self.backupInterval = backupInterval
    }
    
    // Start the periodic backup
    func startPeriodicBackup(messagesPublisher: Published<[String]>.Publisher) {
        messagesPublisher
            .debounce(for: .seconds(backupInterval), scheduler: RunLoop.main)
            .sink { [weak self] messages in
                self?.backupMessages(messages: messages)
            }
            .store(in: &cancellables)
    }
    
    // Backup chat messages by uploading them to the server
    private func backupMessages(messages: [String]) {
        // Create a temporary file for the backup
        guard let filePath = createBackupFile(with: messages) else {
            print("Failed to create backup file.")
            return
        }
        
        // Perform the file upload to the server
        uploadBackupFile(filePath: filePath)
    }
    
    // Create a temporary file containing the chat messages
    private func createBackupFile(with messages: [String]) -> String? {
        let fileManager = FileManager.default
        let fileName = "chat_backup.txt"
        
        guard let tempDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let filePath = tempDir.appendingPathComponent(fileName)
        let messageString = messages.joined(separator: "\n")
        
        do {
            try messageString.write(to: filePath, atomically: true, encoding: .utf8)
            return filePath.path
        } catch {
            print("Error writing to file: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Upload the backup file to the server using a POST request
    private func uploadBackupFile(filePath: String) {
        let fileURL = URL(fileURLWithPath: filePath)
        
        var request = URLRequest(url: URL(string: chatBackupAPI)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // Create the multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let data = createMultipartFormData(fileURL: fileURL, boundary: boundary)
        
        let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
            if let error = error {
                print("Backup upload failed: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Backup upload failed with response: \(String(describing: response))")
                return
            }
            
            print("Backup successfully uploaded.")
        }
        
        task.resume()
    }
    
    // Create multipart form data
    private func createMultipartFormData(fileURL: URL, boundary: String) -> Data {
        var data = Data()
        
        // Add file data to multipart form
        let fileName = fileURL.lastPathComponent
        let fileData = try? Data(contentsOf: fileURL)
        
        if let fileData = fileData {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            data.append(fileData)
            data.append("\r\n".data(using: .utf8)!)
        }
        
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return data
    }
}
