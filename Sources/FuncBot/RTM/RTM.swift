//
//  RTM.swift
//  FuncBot
//
//  Created by Tangent on 04/02/2018.
//

import Foundation
import Starscream

private let heartbeatInterval: TimeInterval = 6
public final class RTM {
    private var _socket: WebSocket?
    private var _timer: Timer?

    private var _eventCallbacks = [(Event) -> ()]()
    
    func addCallback(_ callback: @escaping (Event) -> ()) {
        if Thread.isMainThread {
            _eventCallbacks.append(callback)
        } else {
            DispatchQueue.main.async {
                self._eventCallbacks.append(callback)
            }
        }
    }
    
    func send(_ msg: String) {
        _socket?.write(string: msg)
    }
    
    func connect(url: URL) {
        let socket = WebSocket(url: url)
        _socket = WebSocket(url: url)
        socket.connect()
        _socket = socket
        _bind()
    }
    
    private init() { }
}

extension RTM {
    enum Event {
        case connected
        case disconnected(Error?)
        case getText(String)
    }
}

private extension RTM {
    func _starHeartbeat() {
        let timer = Timer(timeInterval: heartbeatInterval, target: self, selector: #selector(RTM._peng), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .commonModes)
        _timer = timer
    }

    func _stopHeartbeat() {
        _timer?.invalidate()
        _timer = nil
    }
    
    @objc func _peng() {
        _socket?.write(ping: Data())
    }
    
    func _bind() {
        _socket?.onConnect = { [weak self] in
            self?._eventCallbacks.forEach { $0(.connected) }
            self?._starHeartbeat()
        }

        _socket?.onDisconnect = { [weak self] error in
            self?._eventCallbacks.forEach { $0(.disconnected(error)) }
            self?._stopHeartbeat()
        }

        _socket?.onText = { [weak self] text in
            self?._eventCallbacks.forEach { $0(.getText(text)) }
        }
    }
}

// MARK: - IO
public extension RTM {
    static let instance = RTM()
    
    static let loopToRead: IO<String> = IO<String> { send in
        instance.addCallback {
            guard case .getText(let text) = $0 else { return }
            send(text)
        }
    }
    
    static let send: (String) -> IO<()> = { msg in
        return IO<()> { completed in
            instance.send(msg)
            completed(())
        }
    }
    
    static let sendMsg: (Message.Outgoing) -> IO<()> = { msg in
        return IO<()> { completed in
            if let jsonString = msg.jsonString {
                instance.send(jsonString)
            }
            completed(())
        }
    }
}
