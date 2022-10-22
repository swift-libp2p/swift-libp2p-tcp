
import LibP2P
import Multiaddr
import Multicodec

// Install our TCP Tranport on the LibP2P Application
public struct TCP_Embedded: Transport {
    public static var key:String = "tcp"
    
    let application:Application
    public var protocols: [LibP2PProtocol]
    public var proxy: Bool
    public let uuid: UUID
    
    public var sharedClient: ClientBootstrap {
        let lock = self.application.locks.lock(for: Key.self)
        lock.lock()
        defer { lock.unlock() }
        if let existing = self.application.storage[Key.self] {
            return existing
        }
        let new = ClientBootstrap(group: self.application.eventLoopGroup)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                // Do we install the upgrader here or do we let the Connection install the handlers???
                //channel.pipeline.addHandlers(upgrader.channelHandlers(mode: .initiator)) // The MSS Handler itself needs to have access to the Connection Delegate
                channel.eventLoop.makeSucceededVoidFuture()
            }

        self.application.storage.set(Key.self, to: new)

        return new
    }
    
    public func dial(address: Multiaddr) -> EventLoopFuture<Connection> {
        guard let tcp = address.tcpAddress else {
            self.application.logger.warning("Invalid Mutliaddr. TCP can't dial \(address)")
            return self.application.eventLoopGroup.any().makeFailedFuture(Errors.invalidMultiaddr)
        }
        self.application.logger.trace("Attempting to dial \(address)")
        return sharedClient.connect(host: tcp.address, port: tcp.port).flatMap { channel -> EventLoopFuture<Connection> in
            
            self.application.logger.trace("Instantiating new BasicConnectionLight")
            let conn = application.connectionManager.generateConnection(channel: channel, direction: .outbound, remoteAddress: address, expectedRemotePeer: try? PeerID(cid: address.getPeerID() ?? ""))
            
            /// The connection installs the necessary channel handlers here
            self.application.logger.trace("Asking BasicConnectionLight to instantiate new outbound channel")
            
            /// Add the connection to our ConnectionManager
            return self.application.connections.addConnection(conn, on: nil).flatMap {
                /// install the backpressure handler
                channel.pipeline.addHandler(BackPressureHandler(), position: .first).flatMap {
                    conn.initializeChannel().map {
                        //self.onNewOutboundConnection(conn, address).map { _ -> Connection in
                            return conn
                        //}
                    }
                }
            }
        }
    }
    
    public func canDial(address: Multiaddr) -> Bool {
        //address.tcpAddress != nil && !address.protocols().contains(.ws)
        guard let tcp = address.tcpAddress else { return false }
        guard tcp.ip4 else { return false } // Remove once we can dial ipv6 addresses
        guard !address.protocols().contains(.ws) else { return false } // Our TCP Client doesn't support WebSocket Upgrades...
        return true
    }
    
    public func listen(address: Multiaddr) -> EventLoopFuture<Listener> {
        application.eventLoopGroup.any().makeFailedFuture(Errors.notYetImplemeted)
    }
    
    struct Key: StorageKey, LockKey {
        typealias Value = ClientBootstrap
    }

//    struct ConfigurationKey: StorageKey {
//        typealias Value = TCPClient.Configuration
//    }
    
    public enum Errors:Error {
        case notYetImplemeted
        case invalidMultiaddr
        case inboundConnectionAfterApplicationShutdown
    }
}
