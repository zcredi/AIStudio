/// Отправляет эндпоинты на один сервер и декодирует их ответы.
protocol APIClient: Sendable {
    /// Бросает `APIError` или `CancellationError`, если вызывающую задачу отменили.
    func send<Response>(_ endpoint: Endpoint<Response>) async throws -> Response
}
