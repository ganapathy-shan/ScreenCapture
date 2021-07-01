//
//  DisplayTransport.swift
//  ScreenCapture
//
//  Created by Shanmuganathan on 29/06/21.
//

import Foundation
import CocoaAsyncSocket

class DisplayTransport : NSObject, GCDAsyncUdpSocketDelegate {
    
    var hostIP : String = "127.0.0.1"
    var port : UInt16 = 22560
    var socket : GCDAsyncUdpSocket?
    var dispatchQueue = DispatchQueue.init(label: "com.send.queue", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    
    var isConnected : Bool {
        guard let socket = socket else { return false }
        return socket.isConnected()
    }
    
    override init() {
        super.init()
        setUpConnection()
    }
    
    func setUpConnection() {
        self.socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatchQueue)
        guard let socket = self.socket else {
            return
        }
        do {
            try socket.connect(toHost: socket.localHost() ?? "127.0.0.1", onPort: port)
            try socket.enableBroadcast(true)
        } catch let err {
            print(err)
        }
    }
    
    func sendData(data : Data) {
        guard isConnected else {
            print("Socket not connnected. Setup the connection again")
            setUpConnection()
            return
        }
        socket?.send(data, withTimeout: 1000, tag: 0)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        print("Connected")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        print("Error in socket connection \(String(describing: error))")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print("Data Sent")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print("Error in sending Data \(String(describing: error))")
    }
    
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("Socket closed")
    }
}
