/// Location of an API over HTTPS, e.g. host `nebulaapps.site` with base path `/dola`.
struct APIServer: Sendable {
    let host: String
    let basePath: String
}
