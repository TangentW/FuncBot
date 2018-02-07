//
//  Middlewares.swift
//  FuncBot
//
//  Created by Tangent on 07/02/2018.
//

import Foundation

public func baike(appId: String) -> (String) -> IO<String> {
    return { keyword in
        IO { send in
            HTTP.request(path: "https://baike.baidu.com/api/openapi/BaikeLemmaCardApi", body: "appid=\(appId)&bk_key=\(keyword)".data(using: .utf8), method: "POST") {
                if let text: String = $0.json?["abstract"] {
                    send(text)
                }
            }
        }
    }
}

public func huoxing(appId: String) -> (String) -> IO<String> {
    return { content in
        IO { send in
            HTTP.request(path: "http://api.jisuapi.com/fontconvert/convert", body: "appkey=\(appId)&content=\(content)&type=2h".data(using: .utf8), method: "POST") {
                if let text: String = $0.json?["result.rcontent"] {
                    send(text)
                }
            }
        }
    }
}
