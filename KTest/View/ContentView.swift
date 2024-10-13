//
//  ContentView.swift
//  KTest
//
//  Created by Md Zahidul Islam Mazumder on 10/13/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ChatViewModel(backupInterval: 30.0) // Backup every 30 seconds for testing

    var body: some View {
        VStack {
            Text("WebSocket Chat")
                .font(.largeTitle)
                .padding()

            List(viewModel.messages, id: \.self) { message in
                Text(message)
            }

            HStack {
                Button("Connect") {
                    viewModel.connect()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Fetch Messages") {
                    viewModel.fetchMessages()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Disconnect") {
                    viewModel.disconnect()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
    }
}


#Preview {
    ContentView()
}
