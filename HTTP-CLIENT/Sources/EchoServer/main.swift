import NIO

class EchoServerHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let byteBuffer = unwrapInboundIn(data)
        print(byteBuffer.debugDescription)
        _ = ctx.write(wrapOutboundOut(byteBuffer))
    }

    func channelReadComplete(ctx: ChannelHandlerContext) {
        ctx.flush()
        _ = ctx.close()
    }
}

let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let childGroup = MultiThreadedEventLoopGroup(numberOfThreads: 3)

let soReuseAddr = ChannelOptions.socket(
        SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR)
let tcpNoDelay = ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY)
let recvAllocator = ChannelOptions.recvAllocator

let bootstrap = ServerBootstrap(group: eventLoopGroup, childGroup: childGroup)
        .serverChannelOption(soReuseAddr, value: 1)
//        .childChannelOption(tcpNoDelay, value: 1)
        .childChannelOption(soReuseAddr, value: 1)
//        .childChannelOption(recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        .childChannelInitializer { channel in
            channel.pipeline.add(handler: EchoServerHandler())
        }

defer {
    try! childGroup.syncShutdownGracefully()
    try! eventLoopGroup.syncShutdownGracefully()
}

let serverSocketChannel = try bootstrap.bind(host: "localhost", port: 8000).wait()

print("Server started on localhost:8000.")

try serverSocketChannel.closeFuture.wait()

print("Server stopped.")
