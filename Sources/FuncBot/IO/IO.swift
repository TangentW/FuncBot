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
    
    private let _lock = NSRecursiveLock()
    private var _handlers: [Handler] = []
    private var _operation: Operation?
    
    public init(operation: @escaping Operation) {
        _operation = operation
    }
    
    private func _handle(_ value: T) {
        _lock.lock(); defer { _lock.unlock() }
        _handlers.forEach { $0(value) }
    }
    
    private lazy var _activateIfNeed: () = {
        self._operation?(self._handle)
        // Why do that?
        // Before activate, previous IO doesn't retain next IO.
        // So we can use `operation` to make next IO retain previous IO first.
        // Now we need to set `operation` to nil.
        self._operation = nil
    }()
    
    public func subscribe(handler: @escaping Handler) {
        _lock.lock(); defer { _lock.unlock() }
        _handlers.append(handler)
        _ = _activateIfNeed
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

public extension IO {
    static func merge(_ objs: IO...) -> IO {
        return IO { ok in
            objs.forEach { $0.subscribe { ok($0) } }
        }
    }
    
    static func merge(_ objs: [IO]) -> IO {
        return IO { ok in
            objs.forEach { $0.subscribe { ok($0) } }
        }
    }
    
    static func combine<A, B>(_ a: IO<A>, _ b: IO<B>, fun: @escaping (A, B) -> T) -> IO {
        return curry(fun) <^> a <*> b
    }
    
    static func combine<A, B, C>(_ a: IO<A>, _ b: IO<B>, _ c: IO<C>, fun: @escaping (A, B, C) -> T) -> IO {
        return curry(fun) <^> a <*> b <*> c
    }
    
    static func combine<A, B, C, D>(_ a: IO<A>, _ b: IO<B>, _ c: IO<C>, _ d: IO<D>, fun: @escaping (A, B, C, D) -> T) -> IO {
        return curry(fun) <^> a <*> b <*> c <*> d
    }
    
    static func combine<A, B, C, D, E>(_ a: IO<A>, _ b: IO<B>, _ c: IO<C>, _ d: IO<D>, _ e: IO<E>, fun: @escaping (A, B, C, D, E) -> T) -> IO {
        return curry(fun) <^> a <*> b <*> c <*> d <*> e
    }
    
    static func combine<A, B, C, D, E, F>(_ a: IO<A>, _ b: IO<B>, _ c: IO<C>, _ d: IO<D>, _ e: IO<E>, _ f: IO<F>, fun: @escaping (A, B, C, D, E, F) -> T) -> IO {
        return curry(fun) <^> a <*> b <*> c <*> d <*> e <*> f
    }
}

public extension Array {
    func mergeIO<T>() -> IO<T> where Element == IO<T> {
        return IO.merge(self)
    }
}
