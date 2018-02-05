//
//  JSON.swift
//  BearyBot
//
//  Created by Tangent on 01/02/2018.
//  Copyright © 2018 Tangent. All rights reserved.
//

import Foundation

extension Data {
    var json: JSON? {
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: self, options: .allowFragments),
            let value = jsonObject as? [String: Any]
        else { return nil }
        return JSON(value: value)
    }
}

struct JSON {
    let value: [String: Any]
}

extension JSON {
    subscript<T>(cast key: String) -> T? {
        guard let value = self.value[key] else {
            logError("Can't find key \(key)")
            return nil
        }
        guard let ret = value as? T else {
            logError("Can't cast \(value) to \(T.self)")
            return nil
        }
        return ret
    }
    
    subscript<T>(keyPath: String) -> T? {
        var allKey = keyPath.components(separatedBy: ".")
        let valueKey = allKey.removeLast()
        let lastPath = allKey.mapReduce(self) { JSON.init <^> $0[cast: $1] }
        return lastPath >>- { $0[cast: valueKey] }
    }
    
    private func logError(_ desc: String) {
        print("JSON Error: \(desc) | from: \(value)")
    }
}

extension Array {
    func mapReduce<T>(_ initialValue: T, step: (T, Element) -> T?) -> T? {
        var ret: T? = initialValue
        var iterator = makeIterator()
        while let value = ret, let next = iterator.next() {
            ret = step(value, next)
        }
        return ret
    }
}
