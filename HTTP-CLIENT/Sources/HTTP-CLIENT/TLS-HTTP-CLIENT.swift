//
// Created by mike on 2018/08/31.
//

import Foundation
import NIO
import NIOHTTP1
import NIOOpenSSL

class DebugHandler: ChannelInboundHandler {

    typealias InboundIn = Any

    let name: String

    init(_ name: String) {
        self.name = name
    }

    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        NSLog("\(name) channelRead")
        ctx.fireChannelRead(data)
    }

    func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        NSLog("\(name) error found: \(error)")
        ctx.fireErrorCaught(error)
    }
}

func tlsHttpClient() {
    let semaphore = DispatchSemaphore(value: 0)

    let url: GetUrl = GetUrl(scheme: .https, host: "httpbin.org", port: nil, path: ["status", "200"], query: nil)

    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    defer {
        semaphore.wait()
        try! eventLoopGroup.syncShutdownGracefully()
    }

    let tlsConfiguration = TLSConfiguration.forClient()
    let sslContext = try! SSLContext(configuration: tlsConfiguration)
    let sslHandler = try! OpenSSLClientHandler(context: sslContext, serverHostname: url.host)

    let handler = UserHttpResponseHandler(semaphore)

    let bootstrap = ClientBootstrap(group: eventLoopGroup)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .channelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
            .channelInitializer { channel in
                _ = channel.pipeline.add(name: "open-ssl", handler: sslHandler)
                _ = channel.pipeline.add(handler: DebugHandler("ssl"))
                _ = channel.pipeline.addHTTPClientHandlers()
                _ = channel.pipeline.add(handler: DebugHandler("http codec"))
                return channel.pipeline.add(handler: handler)
            }

    func request(channel: Channel) -> EventLoopFuture<Channel> {
        var request = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: HTTPMethod.GET, uri: url.urlString)
        request.headers = HTTPHeaders([
            ("Host", url.host),
            ("User-Agent", "swift-nio"),
            ("Accept", "application/json")
        ])
        _ = channel.write(HTTPClientRequestPart.head(request), promise: nil)
        return channel.writeAndFlush(HTTPClientRequestPart.end(nil)).map { channel }
    }

    _ = bootstrap.connect(host: url.host, port: url.portNumber)
            .then { request(channel: $0) }
}
