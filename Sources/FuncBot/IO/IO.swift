//
//  IO.swift
//  BearyBot
//
//  Created by Tangent on 02/02/2018.
//  Copyright © 2018 Tangent. All rights reserved.
//

import Foundation

// MARK: - IO
public final class IO<T> {
    public typealias Handler = (T) -> ()
    public typealias Operation = (@escaping Handler) -> ()
    
    private var _handler: Handler?
    private let _operation: Operation
    
    public init(operation: @escaping Operation) {
        _operation = operation
    }
    
    private func _callback(value: T) {
        _handler?(value)
    }
    
    public func subscribe(handler: @escaping Handler) {
        _handler = handler
        _operation(_callback)
    }
}

public extension IO {
    static func `return`(_ value: T) -> IO<T> {
        return IO<T> { $0(value) }
    }
    
    static var never: IO<T> {
        return IO<T> { _ in }
    }
    
    func bind<O>(_ fun: @escaping (T) -> IO<O>) -> IO<O> {
        return IO<O> { exec in
            self.subscribe { result in
                fun(result).subscribe { exec($0) }
            }
        }
    }
    
    func map<O>(_ fun: @escaping (T) -> O) -> IO<O> {
        return self.bind { IO<O>.return(fun($0)) }
    }
    
    func apply<O>(_ funIO: IO<(T) -> O>) -> IO<O> {
        return self.bind { value in funIO.map { $0(value) } }
    }
    
    func filter(_ fun: @escaping (T) -> Bool) -> IO<T> {
        return bind { value in
            IO { if fun(value) { $0(value) } }
        }
    }
    
    func filterNil<I>() -> IO<I> where T == I? {
        return filter { $0 != nil }.map { $0! }
    }
}

// MARK: - Runnable
public func run(_ io: IO<()>, with token: String) {
    io.subscribe { }
    guard let (rtmURL, hubotId) = HTTP.fetchRTMInfo(token: token) else {
        return
    }
    Message.hubotId = hubotId
    RTM.instance.connect(url: rtmURL)
    RunLoop.current.run()
}
