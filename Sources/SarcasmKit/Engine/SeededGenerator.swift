import Foundation

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

extension String {
    var stableHash: UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in utf8 {
            h ^= UInt64(byte)
            h = h &* 0x100_0000_01b3
        }
        return h
    }
}
