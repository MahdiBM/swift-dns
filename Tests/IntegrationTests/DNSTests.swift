import DNSClient
import DNSModels
import Logging
import NIOPosix
import Testing

@Suite(.serialized)
struct DNSTests {
    @Test func queryA() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let factory = try MessageFactory<A>.forQuery(name: "example.com")
        let message = factory.message
        let response = try await client.queryA(message: factory, options: .edns)

        #expect(response.header.id == message.header.id)
        #expect(response.header.queryCount > 0)
        #expect(response.header.answerCount > 0)
        /// response.header.nameServerCount is whatever
        #expect(response.header.additionalCount > 0)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        /// `response.header.authenticData` is whatever
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "example.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .A)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count > 1)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .A }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        /// response.answers[].ttl is whatever
        let ipv4s = try response.answers.map {
            try $0.rdata.value
        }
        #expect(
            ipv4s.allSatisfy {
                /// Weird way to check if the IPv4 is not just some zero bytes
                var sum: UInt32 = 0
                for idx in $0.bytes.indices {
                    sum += UInt32($0.bytes[idx])
                }
                return sum != 0
            }
        )

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func queryAAAA() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let factory = try MessageFactory<AAAA>.forQuery(name: "cloudflare.com")
        let message = factory.message
        let response = try await client.queryAAAA(message: factory, options: .edns)

        #expect(response.header.id == message.header.id)
        #expect(response.header.queryCount > 0)
        #expect(response.header.answerCount > 0)
        /// response.header.nameServerCount is whatever
        #expect(response.header.additionalCount > 0)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        #expect(response.header.authenticData == true)
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "cloudflare.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .AAAA)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count > 1)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .AAAA }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        /// response.answers[].ttl is whatever
        let ipv6s = try response.answers.map {
            try $0.rdata.value
        }
        #expect(
            ipv6s.allSatisfy {
                /// Weird way to check if the IPv4 is not just some zero bytes
                var sum: UInt32 = 0
                for idx in $0.bytes.indices {
                    sum += UInt32($0.bytes[idx])
                }
                return sum != 0
            }
        )

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func queryCAA() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let factory = try MessageFactory<CAA>.forQuery(name: "cloudflare.com")
        let message = factory.message
        let response = try await client.queryCAA(message: factory, options: .edns)

        #expect(response.header.id == message.header.id)
        #expect(response.header.queryCount > 0)
        #expect(response.header.answerCount > 0)
        /// response.header.nameServerCount is whatever
        #expect(response.header.additionalCount > 0)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        /// `response.header.authenticData` is whatever
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "cloudflare.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .CAA)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count > 1)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .CAA }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        /// response.answers[].ttl is whatever
        let caa = try response.answers.map {
            try $0.rdata
        }
        #expect(
            caa.allSatisfy {
                $0.rawValue.count > 5
            }
        )

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func queryCERT() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let factory = try MessageFactory<CERT>.forQuery(name: "for-dns-cert-testing.mahdibm.com")
        let message = factory.message
        let response = try await client.queryCERT(message: factory, options: .edns)

        #expect(response.header.id == message.header.id)
        #expect(response.header.queryCount > 0)
        #expect(response.header.answerCount > 0)
        /// response.header.nameServerCount is whatever
        #expect(response.header.additionalCount > 0)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        /// `response.header.authenticData` is whatever
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "for-dns-cert-testing.mahdibm.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .CERT)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count == 1)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .CERT }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        /// response.answers[].ttl is whatever
        let certs = try response.answers.map {
            try $0.rdata
        }
        let expectedCerts = [
            CERT(
                certType: .PKIX,
                keyTag: 12345,
                algorithm: .RSASHA256,
                certData: [
                    0x4c, 0x4a, 0x41, 0x34, 0x56, 0x32, 0x4c, 0x6b, 0x56, 0x51, 0x5a, 0x6c, 0x4c,
                    0x7a, 0x5a, 0x6b, 0x48, 0x6d, 0x41, 0x75, 0x4f, 0x77, 0x4c, 0x31, 0x44, 0x47,
                    0x42, 0x33, 0x70, 0x51, 0x4d, 0x33, 0x56, 0x6d, 0x4c, 0x32, 0x56, 0x54, 0x4d,
                    0x34, 0x44, 0x4a, 0x5a,
                ]
            )
        ]

        #expect(certs.count == expectedCerts.count)

        for (lhs, rhs) in zip(certs, expectedCerts) {
            #expect(lhs.certType == rhs.certType)
            #expect(lhs.keyTag == rhs.keyTag)
            #expect(lhs.algorithm == rhs.algorithm)
            #expect(lhs.certData == rhs.certData)
        }

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func queryCNAMEWwwGithubCom() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let factory = try MessageFactory<CNAME>.forQuery(name: "www.github.com")
        let message = factory.message
        let response = try await client.queryCNAME(message: factory, options: .edns)

        #expect(response.header.id == message.header.id)
        #expect(response.header.queryCount > 0)
        #expect(response.header.answerCount == 1)
        #expect(response.header.nameServerCount == 0)
        #expect(response.header.additionalCount > 0)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        /// `response.header.authenticData` is whatever
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "www.github.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .CNAME)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count == 1)
        let answer = try #require(response.answers.first)
        #expect(answer.nameLabels.isFQDN == true)
        #expect(answer.nameLabels.data == name.data)
        #expect(answer.recordType == .CNAME)
        #expect(answer.dnsClass == .IN)
        #expect(answer.ttl > 0)
        let cname = try answer.rdata
        #expect(cname.name.asString() == "github.com.")

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func queryCNAMERawGithubusercontentCom() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let factory = try MessageFactory<CNAME>.forQuery(name: "raw.githubusercontent.com")
        let message = factory.message
        let response = try await client.queryCNAME(message: factory, options: .edns)

        #expect(response.header.id == message.header.id)
        #expect(response.header.queryCount > 0)
        #expect(response.header.answerCount == 0)
        #expect(response.header.nameServerCount > 0)
        #expect(response.header.additionalCount > 0)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        /// `response.header.authenticData` is whatever
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "raw.githubusercontent.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .CNAME)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count > 0)

        let nameServer = try #require(response.nameServers.first)
        switch nameServer.rdata {
        case .SOA(let soa):
            let mName = soa.mName.asString()
            let rName = soa.rName.asString()
            #expect(mName.count > 5, "mName: \(mName), soa: \(soa)")
            #expect(rName.count > 5, "rName: \(rName), soa: \(soa)")
        default:
            Issue.record("rdata was not of type SOA: \(nameServer.rdata)")
        }

        #expect(response.answers.count == 0)

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func queryCSYNC() async throws {}

    @Test func queryHINFO() async throws {}

    @Test func queryHTTPS() async throws {}

    @Test func queryMX() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let factory = try MessageFactory<MX>.forQuery(name: "mahdibm.com")
        let message = factory.message
        let response = try await client.queryMX(message: factory, options: .edns)

        #expect(response.header.id == message.header.id)
        #expect(response.header.queryCount > 0)
        #expect(response.header.answerCount > 0)
        /// response.header.nameServerCount is whatever
        #expect(response.header.additionalCount > 0)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        /// `response.header.authenticData` is whatever
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "mahdibm.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .MX)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count == 2)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .MX }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        /// response.answers[].ttl is whatever
        let mxs = try response.answers.map {
            try $0.rdata
        }.sorted {
            $0.preference < $1.preference
        }
        let expectedMXs = [
            MX(preference: 10, exchange: try Name(string: "in1-smtp.messagingengine.com.")),
            MX(preference: 20, exchange: try Name(string: "in2-smtp.messagingengine.com.")),
        ]
        #expect(mxs.count == expectedMXs.count)
        for (mx, expectedMX) in zip(mxs, expectedMXs) {
            #expect(mx.preference == expectedMX.preference)
            #expect(mx.exchange.isFQDN == expectedMX.exchange.isFQDN)
            #expect(mx.exchange.data == expectedMX.exchange.data)
            #expect(mx.exchange.borders == expectedMX.exchange.borders)
        }

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func queryNAPTR() async throws {}

    @Test func queryNS() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let factory = try MessageFactory<NS>.forQuery(name: "apple.com")
        let message = factory.message
        let response = try await client.queryNS(message: factory, options: .edns)

        #expect(response.header.id == message.header.id)
        #expect(response.header.queryCount > 0)
        #expect(response.header.answerCount == 4)
        /// response.header.nameServerCount is whatever
        #expect(response.header.additionalCount > 0)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        /// `response.header.authenticData` is whatever
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "apple.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .NS)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count == 4)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .NS }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        /// response.answers[].ttl is whatever
        let nss = try response.answers.map {
            try $0.rdata
        }.sorted {
            $0.name.asString() < $1.name.asString()
        }
        let expectedNSs = [
            NS(name: try Name(string: "a.ns.apple.com.")),
            NS(name: try Name(string: "b.ns.apple.com.")),
            NS(name: try Name(string: "c.ns.apple.com.")),
            NS(name: try Name(string: "d.ns.apple.com.")),
        ]
        #expect(nss.count == expectedNSs.count)
        for (ns, expectedNS) in zip(nss, expectedNSs) {
            #expect(ns.name.isFQDN == expectedNS.name.isFQDN)
            #expect(ns.name.data == expectedNS.name.data)
            #expect(ns.name.borders == expectedNS.name.borders)
        }

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func queryNULL() async throws {}

    @Test func queryOPENPGPKEY() async throws {}

    /// You can't query OPT directly.
    /// OPT is used in every other query, so it's already well-tested.
    @Test func queryOPT() async throws {}

    @Test func queryPTR() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let factory = try MessageFactory<PTR>.forQuery(name: "9.9.9.9.in-addr.arpa")
        let message = factory.message
        let response = try await client.queryPTR(message: factory, options: .edns)

        #expect(response.header.id == message.header.id)
        #expect(response.header.queryCount > 0)
        #expect(response.header.answerCount == 1)
        /// response.header.nameServerCount is whatever
        #expect(response.header.additionalCount > 0)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        /// `response.header.authenticData` is whatever
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "9.9.9.9.in-addr.arpa")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .PTR)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count == 1)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .PTR }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        /// response.answers[].ttl is whatever
        let ptrs = try response.answers.map {
            try $0.rdata
        }
        let expectedPTRs = [
            PTR(name: try Name(string: "dns9.quad9.net."))
        ]
        #expect(ptrs.count == expectedPTRs.count)
        for (ptr, expectedPTR) in zip(ptrs, expectedPTRs) {
            #expect(ptr.name.isFQDN == expectedPTR.name.isFQDN)
            #expect(ptr.name.data == expectedPTR.name.data)
            #expect(ptr.name.borders == expectedPTR.name.borders)
        }

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func querySOA() async throws {}

    @Test func querySRV() async throws {}

    @Test func querySSHFP() async throws {}

    @Test func querySVCB() async throws {}

    @Test func queryTLSA() async throws {}

    @Test func queryTXT() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let factory = try MessageFactory<TXT>.forQuery(name: "example.com")
        let message = factory.message
        let response = try await client.queryTXT(message: factory, options: .edns)

        #expect(response.header.id == message.header.id)
        #expect(response.header.queryCount > 0)
        #expect(response.header.answerCount > 0)
        /// response.header.nameServerCount is whatever
        #expect(response.header.additionalCount > 0)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        /// `response.header.authenticData` is whatever
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "example.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .TXT)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count > 1)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .TXT }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        /// response.answers[].ttl is whatever
        let txts = try response.answers.map {
            try $0.rdata
        }
        #expect(txts.allSatisfy { ($0.txtData.first?.count ?? 0) > 5 })

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func queryUnknown() async throws {}

    @Test func queryUpdate0() async throws {}
}
