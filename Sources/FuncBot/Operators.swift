//
//  Operators.swift
//  BearyBot
//
//  Created by Tangent on 02/02/2018.
//  Copyright © 2018 Tangent. All rights reserved.
//

import Foundation

precedencegroup Bind {
    associativity: left
    higherThan: DefaultPrecedence
}

precedencegroup FunctorMap {
    associativity: left
    higherThan: Bind
}

precedencegroup FunctionComposition {
    associativity: right
    higherThan: MultiplicationPrecedence
}


infix operator <^> : FunctorMap
infix operator <*> : FunctorMap
infix operator >>- : Bind
infix operator <- : FunctionComposition

// MARK: - Function
public func <- <I, O, M>(lhs: @escaping (M) -> O, rhs: @escaping (I) -> (M)) -> (I) -> (O) {
    return { lhs(rhs($0)) }
}

// MARK: - IO
public func >>- <I, O>(lhs: IO<I>, rhs: @escaping (I) -> IO<O>) -> IO<O> {
    return lhs.bind(rhs)
}

public func >> <I, O>(lhs: IO<I>, rhs: IO<O>) -> IO<O> {
    return lhs >>- { _ in rhs }
}

public func <^> <I, O>(lhs: @escaping (I) -> O, rhs: IO<I>) -> IO<O> {
    return rhs.map(lhs)
}

public func <*> <I, O>(lhs: IO<(I) -> O>, rhs: IO<I>) -> IO<O> {
    return rhs.apply(lhs)
}

// MARK: - Optional
public func >>- <I, O>(lhs: I?, rhs: (I) -> O?) -> O? {
    return lhs.flatMap(rhs)
}

public func <^> <I, O>(lhs: (I) -> O, rhs: I?) -> O? {
    return rhs.map(lhs)
}

public func <*> <I, O>(lhs: ((I) -> O)?, rhs: I?) -> O? {
    return rhs.flatMap { value in lhs.map { $0(value) } }
}
