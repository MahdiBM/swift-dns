extension UInt8 {
    @inlinable
    var isASCIIAlphanumeric: Bool {
        /// TODO: make sure `ClosedRange.contains` indeed has a negative performance impact.
        /// If not, just use that.
        let latin_0to9_start = 0x30
        let latin_0to9_end = 0x39
        let latin_AtoZ_start = 0x41
        let latin_AtoZ_end = 0x5A
        let latin_atoz_start = 0x61
        let latin_atoz_end = 0x7A
        return self >= latin_0to9_start && self <= latin_0to9_end
            || self >= latin_AtoZ_start && self <= latin_AtoZ_end
            || self >= latin_atoz_start && self <= latin_atoz_end
    }

    @inlinable
    var isASCII: Bool {
        self & 0b1000_0000 == 0
    }

    @inlinable
    var isUppercasedASCII: Bool {
        self >= 0x41 && self <= 0x5A
    }

    @inlinable
    static var asciiPrintableStart: UInt8 {
        0x20
    }

    @inlinable
    static var asciiPrintableEnd: UInt8 {
        0x7E
    }

    @inlinable
    static var asciiEqual: UInt8 {
        0x3D
    }

    @inlinable
    static var asciiSemicolon: UInt8 {
        0x3B
    }

    @inlinable
    static var asciiHyphenMinus: UInt8 {
        0x2D
    }

    @inlinable
    static var asciiSpace: UInt8 {
        0x20
    }

    @inlinable
    static var asciiTab: UInt8 {
        0x09
    }

    @inlinable
    static var asciiStar: UInt8 {
        0x2A
    }

    @inlinable
    static var asciiBackslash: UInt8 {
        0x5C
    }

    @inlinable
    static var asciiDot: UInt8 {
        0x2E
    }

    @inlinable
    static var nullByte: UInt8 {
        0x00
    }
}
