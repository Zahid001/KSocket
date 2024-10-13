//
//  WebSocketManager.swift
//  KTest
//
//  Created by Md Zahidul Islam Mazumder on 10/13/24.
//

import NWWebSocket
import Combine
import Foundation
import Network


class WebSocketManager: ObservableObject {
    
    static let shared = WebSocketManager()

    private var webSocket: NWWebSocket?
    /*@Published var messages: [String] = []*/ // Store received messages
    private var backupTimer: Timer?

    // Define a publisher to notify when new messages are received
    var messagePublisher = PassthroughSubject<String, Never>()
        
    
    // Connect WebSocket
    func connect() {
        let url = URL(string: "wss://api.quarkshub.com/ws?_id=1001")!
        webSocket = NWWebSocket(url: url,connectAutomatically: true)
        webSocket?.delegate = self
        webSocket?.connect()
    }

    // Send a message to the WebSocket (join channel or fetch keys)
    func sendMessage(_ message: String) {
        webSocket?.send(string: message)
    }

    // Handle messages received from WebSocket
    func handleReceivedMessage(string: String) {
        
        print("Received message: \(string)")
        
        // Attempt to parse the received message as JSON
        if let data = string.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let msgLines = json["replygetkeys"] as? [String] {
                    // Notify the ViewModel about the received messages
                    for message in msgLines {
                        messagePublisher.send(message) // Send each message to the publisher
                    }
                } else {
                    print("No replygetkeys found in message")
                }
            } catch {
                print("Failed to parse message as JSON: \(error.localizedDescription)")
            }
        }
    }

    // Send join channel message
    private func sendJoinChannelMessage() {
        let joinMessage = "{\"join\":\"general\", \"notifyjoin\":true, \"notifyleave\":true}"
        webSocket?.send(string: joinMessage)
    }
    
    // Disconnect WebSocket
    func disconnect() {
        webSocket?.disconnect()
        
    }

    // Fetch messages (send getkeys message)
    func fetchMessages() {
        let fetchMessage = "{\"getkeys\":\"_channel_*\", \"skip\":0, \"limit\":100}"
        webSocket?.send(string: fetchMessage)
    }
}


extension WebSocketManager: WebSocketConnectionDelegate {
 
    func webSocketDidConnect(connection: WebSocketConnection) {
        // Respond to a WebSocket connection event
        sendJoinChannelMessage()
        fetchMessages()
    }

    func webSocketDidDisconnect(connection: WebSocketConnection,
                                closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        // Respond to a WebSocket disconnection event
    }

    func webSocketViabilityDidChange(connection: WebSocketConnection, isViable: Bool) {
        // Respond to a WebSocket connection viability change event
    }

    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, NWError>) {
        // Respond to when a WebSocket connection migrates to a better network path
        // (e.g. A device moves from a cellular connection to a Wi-Fi connection)
    }

    func webSocketDidReceiveError(connection: WebSocketConnection, error: NWError) {
        // Respond to a WebSocket error event
        print("error",error)
    }

    func webSocketDidReceivePong(connection: WebSocketConnection) {
        // Respond to a WebSocket connection receiving a Pong from the peer
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        // Respond to a WebSocket connection receiving a `String` message
        print("string ",string)
        handleReceivedMessage(string: string)
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        // Respond to a WebSocket connection receiving a binary `Data` message
    }
}

