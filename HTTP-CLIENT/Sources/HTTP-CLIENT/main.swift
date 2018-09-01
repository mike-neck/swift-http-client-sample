import Foundation

//name()

//let semaphore = DispatchSemaphore(value: 0)
//
//let max = 130
//
//for id in 0..<max {
//    DispatchQueue.global(qos: .default).async {
//        Thread.sleep(forTimeInterval: 2)
//        NSLog(" - \(Thread.current.description) - id: \(id)")
//        guard id == (max - 1) else {
//            return
//        }
//        NSLog("signal on 99")
//        semaphore.signal()
//    }
//}
//
//semaphore.wait()

tlsHttpClient()
