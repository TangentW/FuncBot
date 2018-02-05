import XCTest
@testable import FuncBot

class FuncBotTests: XCTestCase {
    
    func testExample() {
        let baike: (String) -> IO<String> = { keyword in
            IO { send in
                let appid = ""
                var request = URLRequest(url: URL(string: "https://baike.baidu.com/api/openapi/BaikeLemmaCardApi")!)
                request.httpBody = "appid=\(appid)&bk_key=\(keyword)".data(using: .utf8)
                request.httpMethod = "POST"
                URLSession.shared.dataTask(with: request){ data, _, _ in
                    guard let data = data, let desc: String = data.json?["abstract"] else { return }
                    send(desc)
                }.resume()
            }
        }
        
        let main = RTM.loopToRead
            >>- Message.filter(for: Message.Normal.self)
            >>- Message.replyBind(refer: true, baike)
            >>- RTM.sendMsg
        
        FuncBot.run(main, with: "ae281bd8fce05519b25837b61b95260d")
    }
    
    static var allTests = [
        ("testExample", testExample),
    ]
}
