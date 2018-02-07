# FuncBot

BearyChat FP(functional-programming) hubot SDK.

## Usage
You just need to invoke only one function:
```Swift
run(main, with: "your_rtm_token")
```

The type of `main` is `IO<()>`.

---

```
let main = RTM.loopToRead >>- Console.echo
run(main, with: "your_rtm_token")
```

So you can loop to read hubot incoming messages and print it in the console.

---

Call `RTM.sendMsg` to send `Outgoing` message.

```Swift
let main = RTM.loopToRead
    >>- Console.debug { print("Did read string: \($0)") }
    >>- Message.filter(for: Message.Normal.self)
    >>- Message.map {
        Message.Outgoing(type: .P2P(to: $0.uid),
                                vchannelId: $0.vchannelId,
                                text: "Hello " + $0.text,
                                referKey: $0.key)
    }
    >>- RTM.sendMsg

run(main, with: "your_rtm_token")
```

### Sample

Create `百度百科` hubot.

```Swift
let baike: (String) -> IO<String> = { keyword in
    IO { send in
        let appid = ""
        var request = URLRequest(url: URL(string: "https://baike.baidu.com/api/openapi/BaikeLemmaCardApi")!)
        request.httpBody = "appid=\(appid)&bk_key=\(keyword)".data(using: .utf8)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request){ data, _, _ in
            guard let data = data, let desc: String = data.json?["abstract"] else {
                print("Parse error!")
                return 
            }
            send(desc)
        }.resume()
    }
}

let main = RTM.loopToRead
    >>- Message.filter(for: Message.Normal.self)
    >>- Message.replyBind(refer: true, baike)
    >>- RTM.sendMsg

run(main, with: "your_rtm_token")

```


