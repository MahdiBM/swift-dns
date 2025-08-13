public import DNSModels
public import Synchronization
public import _DNSConnectionPool

package import struct Logging.Logger
package import protocol NIOCore.EventLoopGroup

#if ServiceLifecycleSupport
public import ServiceLifecycle
#endif

@available(swiftDNSApplePlatforms 13, *)
public struct TCPDNSClientTransportConfiguration: Sendable {
    /// Connection configuration
    public var connectionConfiguration: DNSConnectionConfiguration
    /// Connection pool configuration
    public var connectionPoolConfiguration: DNSConnectionPoolConfiguration
    /// Keep-alive behavior
    public var keepAliveBehavior: KeepAliveBehavior

    ///  Initialize DNSClientConfiguration
    /// - Parameters
    ///   - connectionConfiguration: Connection configuration
    ///   - connectionPool: Connection pool configuration
    ///   - keepAliveBehavior: Connection keep alive behavior
    public init(
        connectionConfiguration: DNSConnectionConfiguration = .init(),
        connectionPoolConfiguration: DNSConnectionPoolConfiguration = .init(),
        keepAliveBehavior: KeepAliveBehavior = .init()
    ) {
        self.connectionConfiguration = connectionConfiguration
        self.connectionPoolConfiguration = connectionPoolConfiguration
        self.keepAliveBehavior = keepAliveBehavior
    }
}

/// Configuration for the DNS client
@available(swiftDNSApplePlatforms 26, *)
@usableFromInline
package actor TCPDNSClientTransport {
    package let serverAddress: DNSServerAddress
    package let configuration: TCPDNSClientTransportConfiguration
    @usableFromInline
    let connectionPool: TCPConnectionPool
    let eventLoopGroup: any EventLoopGroup
    let logger: Logger

    @usableFromInline
    let isRunning: Atomic<Bool>

    package init(
        serverAddress: DNSServerAddress,
        configuration: TCPDNSClientTransportConfiguration = .init(),
        eventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        logger: Logger = .noopLogger
    ) throws {
        let tcpConnectionFactory = try ConnectionFactory(
            configuration: configuration.connectionConfiguration,
            serverAddress: serverAddress
        )
        self.serverAddress = serverAddress
        self.configuration = configuration
        self.connectionPool = TCPConnectionPool(
            configuration: configuration.connectionPoolConfiguration.toConnectionPoolConfig(),
            idGenerator: IncrementalIDGenerator(),
            requestType: ConnectionRequest<DNSConnection>.self,
            keepAliveBehavior: NoOpKeepAliveBehavior(connectionType: DNSConnection.self),
            observabilityDelegate: DNSClientMetrics(logger: logger),
            clock: .continuous
        ) { (connectionID, pool) in
            var logger = logger
            logger[metadataKey: "dns_tcp_conn_id"] = "\(connectionID)"

            let connection = try await tcpConnectionFactory.makeTCPConnection(
                address: serverAddress,
                connectionID: connectionID,
                eventLoop: eventLoopGroup.next(),
                logger: logger
            )

            return ConnectionAndMetadata(connection: connection, maximalStreamsOnConnection: 1)
        }
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
        self.isRunning = Atomic(false)
    }

    /// Run TCPDNSClientTransport's connection pool
    @inlinable
    package func run(preRunHook: @Sendable @escaping () async -> Void = {}) async {
        let (_, old) = self.isRunning.compareExchange(
            expected: false,
            desired: true,
            ordering: .relaxed
        )
        precondition(
            !old,
            "TCPDNSClientTransport.run() should just be called once from `DNSClient.run()`!"
        )
        #if ServiceLifecycleSupport
        await cancelWhenGracefulShutdown {
            await preRunHook()
            await self.connectionPool.run()
        }
        #else
        await preRunHook()
        await self.connectionPool.run()
        #endif
    }

    /// Send a query to the DNS server.
    /// - Parameters:
    ///   - factory: The factory to produce a query message with.
    ///   - options: The options for producing the query message.
    ///   - channel: The channel type to send the query on.
    ///   - isolation: The isolation on which the query will be sent.
    ///
    /// - Returns: The query response.
    @usableFromInline
    package func query(
        message factory: consuming MessageFactory<some RDataConvertible>,
        options: DNSRequestOptions = [],
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> Message {
        try await self.withConnection(
            message: factory,
            options: options,
            isolation: isolation
        ) { factory, options, conn in
            try await self.query(
                message: factory,
                options: options,
                connection: conn,
                isolation: isolation
            )
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension TCPDNSClientTransport {
    @usableFromInline
    func query(
        message factory: consuming MessageFactory<some RDataConvertible>,
        options: DNSRequestOptions = [],
        connection: DNSConnection,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> Message {
        try await connection.send(
            message: factory,
            options: options
        )
    }

    /// Get connection from connection pool and run operation using connection
    ///
    /// - Parameters:
    ///   - isolation: Actor isolation
    ///   - operation: Closure handling DNS connection
    /// - Returns: Value returned by closure
    @usableFromInline
    func withConnection<RDataConv: RDataConvertible>(
        message factory: consuming MessageFactory<RDataConv>,
        options: DNSRequestOptions,
        isolation: isolated (any Actor)? = #isolation,
        operation: (
            consuming MessageFactory<RDataConv>,
            DNSRequestOptions,
            DNSConnection
        ) async throws -> Message
    ) async throws -> Message {
        let lease = try await self.leaseConnection()

        defer { lease.release() }

        return try await operation(factory, options, lease.connection)
    }

    func leaseConnection() async throws -> ConnectionLease<DNSConnection> {
        if !self.isRunning.load(ordering: .relaxed) {
            self.logger.warning(
                "Trying to lease connection from `TCPDNSClientTransport`, but `TCPDNSClientTransport.run()` hasn't been called yet from `DNSClient.run()`."
            )
        }
        return try await self.connectionPool.leaseConnection()
    }
}
