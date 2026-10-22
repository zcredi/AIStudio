protocol CacheClearing: Sendable {
    /// Байты в кэшах, которые можно восстановить: скачанные превью и HTTP-ответы.
    func cacheSize() async -> Int64
    func clearCache() async
}
