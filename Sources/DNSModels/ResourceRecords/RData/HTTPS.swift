/// HTTPS is really a derivation of the original SVCB record data. See SVCB for more documentation
public struct HTTPS: Sendable {
    public var svcb: SVCB
}

extension HTTPS {
    package init(from buffer: inout DNSBuffer) throws {
        self.svcb = try SVCB(from: &buffer)
    }
}

extension HTTPS {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.svcb.encode(into: &buffer)
    }
}

extension HTTPS: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .HTTPS(let https):
            self = https
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .HTTPS(self)
    }
}

extension HTTPS: Queryable {
    @inlinable
    public static var recordType: RecordType { .HTTPS }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
