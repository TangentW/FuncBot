import Foundation

public func run(_ io: IO<()>, with token: String) {
    var cycleCount = 1
    guard let (rtmURL, hubotId) = HTTP.fetchRTMInfo(token: token) else {
        return
    }
    Message.hubotId = hubotId
    RTM.instance.connect(url: rtmURL)
    io.subscribe {
        print("------ Cycle \(cycleCount) ------")
        cycleCount += 1
    }
    RunLoop.current.run()
}
