//
//  HTTP.swift
//  FuncBotPackageDescription
//
//  Created by Tangent on 04/02/2018.
//

import Foundation

final class HTTP {
    static func fetchRTMInfo(token: String) -> (URL, String)? {
        let url = URL(string: "https://rtm.bearychat.com/start")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "token=\(token)".data(using: .utf8)
        
        var urlString: String?
        var id: String?
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { data, _, error in
            defer { semaphore.signal() }
            guard let data = data else {
                if let error = error {
                    print(error)
                }
                return
            }
            guard let jsonValue = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any] else {
                print("Can't fetch JSON from response data")
                return
            }
            let json = JSON(value: jsonValue)
            urlString = json["result.ws_host"]
            id = json["result.user.id"]
        }.resume()
        semaphore.wait()
        let create: (URL) -> (String) -> (URL, String) = { a in { b in (a, b) } }
        return create <^> (urlString >>- URL.init) <*> id
    }
}

