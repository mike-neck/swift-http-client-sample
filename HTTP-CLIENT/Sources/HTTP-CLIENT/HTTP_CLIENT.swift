import Foundation
import NIO
import NIOHTTP1

extension ByteBuffer {
    var size: Int {
        return self.writerIndex - self.readerIndex
    }
}

class UserHttpResponseHandler: ChannelInboundHandler {

    let semaphore: DispatchSemaphore

    init(_ semaphore: DispatchSemaphore) {
        self.semaphore = semaphore
    }

    typealias InboundIn = HTTPClientResponsePart

    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let httpResponsePart = unwrapInboundIn(data)
        switch httpResponsePart {
        case .head(let httpResponseHeader):
            NSLog("Status : \(httpResponseHeader.status.code) \(httpResponseHeader.status.reasonPhrase)")
            NSLog(httpResponseHeader.version.description)
            if httpResponseHeader.isKeepAlive {
                NSLog("Connection : Keep-Alive")
            }
            for (name, value) in httpResponseHeader.headers {
                NSLog("\(name) : \(value)")
            }
        case .body(var buffer):
            let res: String? = buffer.readString(length: buffer.size)
            if let body = res {
                NSLog("----")
                NSLog(body)
            } else {
                NSLog("--empty--")
                NSLog("----")
            }
        case .end(_):
            NSLog("----end")
        }
        semaphore.signal()
    }

    func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        NSLog("error caught: \(error)")
        for symbol in Thread.callStackSymbols {
            NSLog("\t\(symbol)")
        }
        defer {
            _ = ctx.channel.close()
        }
        semaphore.signal()
    }
}

enum Scheme {
    case http
    case https

    var port: Int {
        get {
            switch (self) {
            case .http: return 80
            case .https: return 443
            }
        }
    }
}

struct GetUrl {
    let scheme: Scheme
    let host: String
    let port: Int?
    let path: [String]
    let query: String?

    func portPart() -> String {
        if let p = port {
            return ":\(p)"
        } else {
            return ""
        }
    }

    var portNumber: Int {
        get {
            if let number = port {
                return number
            }
            return scheme.port
        }
    }

    var urlString: String {
        get {
            let path: String = self.path.joined(separator: "/")
            return "\(self.scheme)://\(self.host)\(portPart())/\(path)\(queryString)"
        }
    }

    var queryString: String {
        get {
            if let q = query {
                if let qe = q.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) {
                    return "?\(qe)"
                } else {
                    return "?\(q)"
                }
            } else {
                return ""
            }
        }
    }
}

func name() {
    let semaphore = DispatchSemaphore(value: 0)

    let url = GetUrl(scheme: .http, host: "localhost", port: 8080, path: ["foo"], query: "time_zone=Asia/Tokyo")

    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    defer {
        semaphore.wait()
        try! eventLoopGroup.syncShutdownGracefully()
    }
    let handler = UserHttpResponseHandler(semaphore)

    _ = ClientBootstrap(group: eventLoopGroup)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .channelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
            .channelInitializer { channel in
                let pipeline: ChannelPipeline = channel.pipeline
                _ = pipeline.addHTTPClientHandlers()
                return pipeline.add(handler: handler)
            }
            .connect(host: url.host, port: url.portNumber)
            .then({ (channel: Channel) in return runRequest(channel: channel, url: url) })
}

func runRequest(channel: Channel, url: GetUrl) -> EventLoopFuture<Channel> {
    var request = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: HTTPMethod.GET, uri: url.urlString)
    request.headers = HTTPHeaders([
        ("Host", url.host),
        ("User-Agent", "swift-nio"),
        ("Accept", "application/json")
    ])
    NSLog("sending request")
    _ = channel.write(HTTPClientRequestPart.head(request))
    return channel.writeAndFlush(HTTPClientRequestPart.end(nil)).map {
        channel
    }
}
