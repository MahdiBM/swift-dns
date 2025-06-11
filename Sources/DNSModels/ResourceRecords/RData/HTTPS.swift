/// HTTPS is really a derivation of the original SVCB record data. See SVCB for more documentation
@available(macOS 26.0, *)
public struct HTTPS: Sendable {
    public var svcb: SVCB
}

@available(macOS 26.0, *)
extension HTTPS {
    package init(from buffer: inout DNSBuffer) throws {
        self.svcb = try SVCB(from: &buffer)
    }
}

@available(macOS 26.0, *)
extension HTTPS {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.svcb.encode(into: &buffer)
    }
}
