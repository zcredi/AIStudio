@testable import AIStudio

actor FakeCacheStorage: CacheClearing {
    private(set) var clearCount = 0
    private var size: Int64

    init(size: Int64) {
        self.size = size
    }

    func cacheSize() async -> Int64 {
        size
    }

    func clearCache() async {
        clearCount += 1
        size = 0
    }
}
