//
//  ChatBackupViewModel.swift
//  KTest
//
//  Created by Md Zahidul Islam Mazumder on 10/13/24.
//

import Foundation
import Combine

class ChatViewModel: ObservableObject {
    
    // Published properties to bind with the SwiftUI view
    @Published var messages: [String] = []
    @Published var isConnected: Bool = false
    
    private var webSocketManager: WebSocketManager
    private var backupManager: BackupManager?
    private var cancellables = Set<AnyCancellable>()

    init(webSocketManager: WebSocketManager = WebSocketManager(), backupInterval: TimeInterval = 60.0) {
        self.webSocketManager = webSocketManager
        
        // Initialize the BackupManager with the desired backup interval (in seconds)
        self.backupManager = BackupManager(backupInterval: backupInterval)
        
        // Observe the WebSocketManager's messagePublisher
        webSocketManager.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMessage in
                self?.messages.append(newMessage)
            }
            .store(in: &cancellables)
        
        // Start the periodic backup of messages
        backupManager?.startPeriodicBackup(messagesPublisher: $messages)
    }

    // Call the connect method from WebSocketManager to connect to the server
    func connect() {
        webSocketManager.connect()
        isConnected = true
    }

    // Call the WebSocketManager to send a join channel message or fetch keys
    func joinChannel() {
        let joinMessage = "{\"join\":\"general\", \"notifyjoin\":true, \"notifyleave\":true}"
        webSocketManager.sendMessage(joinMessage)
    }

    // Call the WebSocketManager to fetch messages
    func fetchMessages() {
        let fetchMessage = "{\"getkeys\":\"_channel_*\", \"skip\":0, \"limit\":100}"
        webSocketManager.sendMessage(fetchMessage)
    }
    
    // Disconnect WebSocket
    func disconnect() {
        // Implement disconnection logic if needed
        isConnected = false
    }
}
