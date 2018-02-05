//
//  Console.swift
//  BearyBot
//
//  Created by Tangent on 04/02/2018.
//  Copyright © 2018 Tangent. All rights reserved.
//

import Foundation

// Print
public enum Console { }

public extension Console {
    static let putStr: (String) -> IO<()> = { print($0); return IO.return(()) }
    static let putStrLn: (String) -> IO<()> = putStr <- { $0 + "\n" }
    static let echo: (Any) -> IO<()> = putStr <- { String(describing: $0) }
    static let echoLn: (Any) -> IO<()> = putStrLn <- { String(describing: $0) }
    
    static func debug<T>(_ todo: @escaping (T) -> ()) -> (T) -> IO<T> {
        return { value in
            todo(value)
            return IO.return(value)
        }
    }
}
