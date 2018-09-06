import NIO

class EchoClientInHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer

    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        var byteBuffer = unwrapInboundIn(data)
        let message = byteBuffer.readString(length: byteBuffer.readableBytes)
        if let msg = message {
            print(msg)
        } else {
            print("[[no message returned]]")
        }
    }

    func channelReadComplete(ctx: ChannelHandlerContext) {
        let _ = ctx.channel.close()
    }

    func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error caught: \(error)")
        _ = ctx.channel.close()
    }
}

class EchoClientOutHandler: ChannelOutboundHandler {
    typealias OutboundOut = ByteBuffer
    typealias OutboundIn = String

    func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let string = unwrapOutboundIn(data)
        var byteBuffer = ctx.channel.allocator.buffer(capacity: string.utf8.count)
        byteBuffer.write(string: string)
        ctx.write(wrapOutboundOut(byteBuffer), promise: promise)
    }
}

let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

let soReuseAddr = ChannelOptions.socket(
        SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR)

let bootstrap = ClientBootstrap(group: eventLoopGroup)
        .channelOption(soReuseAddr, value: 1)
        .channelInitializer { channel in
            _ = channel.pipeline.add(handler: EchoClientOutHandler())
            return channel.pipeline.add(handler: EchoClientInHandler())
        }

let future = bootstrap.connect(host: "localhost", port: 8000)
        .then { (channel: Channel) -> EventLoopFuture<Channel> in
            return channel.writeAndFlush("Hello from client").map { channel }
        }

defer {
    try! future.wait().closeFuture.wait()
    try! eventLoopGroup.syncShutdownGracefully()
}

