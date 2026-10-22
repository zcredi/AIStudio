import Foundation

/// Эндпоинты PixVerse v1. `user_id` и `app_id` добавляет `ClientIdentityInterceptor`.
enum PixVerseAPI {
    static func templates(appID: String) -> Endpoint<PixVerseCatalogDTO> {
        .get("/api/v1/get_templates/\(appID)")
    }

    /// `image` — стартовый кадр в JPEG.
    static func templateToVideo(templateID: Int, image: Data, quality: String) -> Endpoint<PixVerseGenerationDTO> {
        var form = MultipartFormData()
        form.append(String(templateID), name: "template_id")
        form.append(quality, name: "quality")
        form.append(image, name: "image", fileName: "image.jpg", mimeType: "image/jpeg")
        // Загрузка фото на медленном соединении идёт дольше обычного запроса.
        return .post("/api/v1/template2video", body: .multipart(form), timeout: RequestTimeout.generation)
    }

    static func status(generationID: Int) -> Endpoint<PixVerseStatusDTO> {
        .get("/api/v1/status", queryItems: [URLQueryItem(name: "id", value: String(generationID))])
    }
}
