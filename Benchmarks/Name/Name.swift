import Benchmark
import DNSModels
import NIOCore

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.maxDuration = .seconds(5)

    var buffer = DNSBuffer()
    var startIndex = 0

    Benchmark(
        "google_dot_com_Binary_Parsing_CPU_2M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000,
            setup: {
                buffer = DNSBuffer(bytes: [
                    0x06, 0x67, 0x6f, 0x6f,
                    0x67, 0x6c, 0x65, 0x03,
                    0x63, 0x6f, 0x6d, 0x00,
                ])
                startIndex = buffer.readerIndex
            }
        )
    ) { benchmark in
        for _ in 0..<2_000_000 {
            buffer.moveReaderIndex(to: startIndex)
            let name = try Name(from: &buffer)
            blackHole(name)
        }
    }

    Benchmark(
        "google_dot_com_Binary_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
            setup: {
                buffer = DNSBuffer(bytes: [
                    0x06, 0x67, 0x6f, 0x6f,
                    0x67, 0x6c, 0x65, 0x03,
                    0x63, 0x6f, 0x6d, 0x00,
                ])
                startIndex = buffer.readerIndex
            }
        )
    ) { benchmark in
        buffer.moveReaderIndex(to: startIndex)
        benchmark.startMeasurement()
        let name = try Name(from: &buffer)
        blackHole(name)
    }

    Benchmark(
        "app-analytics-services_dot_com_Binary_Parsing_CPU_2M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000,
            setup: {
                buffer = DNSBuffer(bytes: [
                    0x16, 0x61, 0x70, 0x70,
                    0x2d, 0x61, 0x6e, 0x61,
                    0x6c, 0x79, 0x74, 0x69,
                    0x63, 0x73, 0x2d, 0x73,
                    0x65, 0x72, 0x76, 0x69,
                    0x63, 0x65, 0x73, 0x03,
                    0x63, 0x6f, 0x6d, 0x00,
                ])
                startIndex = buffer.readerIndex
            }
        )
    ) { benchmark in
        for _ in 0..<2_000_000 {
            buffer.moveReaderIndex(to: startIndex)
            let name = try Name(from: &buffer)
            blackHole(name)
        }
    }

    Benchmark(
        "app-analytics-services_dot_com_Binary_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
            setup: {
                buffer = DNSBuffer(bytes: [
                    0x16, 0x61, 0x70, 0x70,
                    0x2d, 0x61, 0x6e, 0x61,
                    0x6c, 0x79, 0x74, 0x69,
                    0x63, 0x73, 0x2d, 0x73,
                    0x65, 0x72, 0x76, 0x69,
                    0x63, 0x65, 0x73, 0x03,
                    0x63, 0x6f, 0x6d, 0x00,
                ])
                startIndex = buffer.readerIndex
            }
        )
    ) { benchmark in
        buffer.moveReaderIndex(to: startIndex)
        benchmark.startMeasurement()
        let name = try Name(from: &buffer)
        blackHole(name)
    }

    let google = "google.com"
    Benchmark(
        "google_dot_com_String_Parsing_CPU_200K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000,
        )
    ) { benchmark in
        for _ in 0..<200_000 {
            let name = try! Name(domainName: google)
            blackHole(name)
        }
    }

    Benchmark(
        "google_dot_com_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
        )
    ) { benchmark in
        let name = try! Name(domainName: google)
        blackHole(name)
    }

    let appAnalyticsServices = "app-analytics-services.com"
    Benchmark(
        "app-analytics-services_dot_com_String_Parsing_CPU_200K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000,
        )
    ) { benchmark in
        for _ in 0..<200_000 {
            let name = try! Name(domainName: appAnalyticsServices)
            blackHole(name)
        }
    }

    Benchmark(
        "app-analytics-services_dot_com_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
        )
    ) { benchmark in
        let name = try! Name(domainName: appAnalyticsServices)
        blackHole(name)
    }

    let name1 = try! Name(domainName: "google.com.")
    let name2 = try! Name(domainName: "google.com.")
    Benchmark(
        "Equality_Check_Identical_CPU_200M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 100_000_000,
        )
    ) { benchmark in
        for _ in 0..<200_000_000 {
            blackHole(name1 == name2)
        }
    }

    Benchmark(
        "Equality_Check_Identical_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
        )
    ) { benchmark in
        blackHole(name1 == name2)
    }
}
