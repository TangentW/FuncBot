//
//  HTTP.swift
//  FuncBotPackageDescription
//
//  Created by Tangent on 04/02/2018.
//

import Foundation

final class HTTP {
    static func request(path: String, body: Data?, method: String, completion: @escaping (Data) -> ()) {
        guard let url = URL(string: path) else { print("Can't create URL!"); return }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { data, _ , error in
            guard let data = data else {
                var errorString = "Network error! "
                if let error = error {
                    errorString.append(error.localizedDescription)
                }
                print(errorString)
                return
            }
            completion(data)
            }.resume()
    }
    
    static func fetchRTMInfo(token: String) -> (URL, String)? {
        var urlString: String?
        var id: String?
        let semaphore = DispatchSemaphore(value: 0)
        request(path: "https://rtm.bearychat.com/start", body: "token=\(token)".data(using: .utf8), method: "POST") {
            defer { semaphore.signal() }
            guard let json = $0.json else {
                print("Can't fetch JSON"); return
            }
            urlString = json["result.ws_host"]
            id = json["result.user.id"]
        }
        semaphore.wait()
        let create: (URL) -> (String) -> (URL, String) = { a in { b in (a, b) } }
        return create <^> (urlString >>- URL.init) <*> id
    }
}

