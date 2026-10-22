/// Адрес API по HTTPS, например хост `nebulaapps.site` с базовым путём `/pixverse`.
/// Базовый путь пустой, если пути эндпоинтов начинаются от корня хоста.
struct APIServer: Sendable {
    let host: String
    let basePath: String
}
