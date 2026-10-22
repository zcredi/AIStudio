import Foundation

/// Пропорции сгенерированного видео. У API нет параметра формата: видео повторяет
/// стартовый кадр, поэтому приложение обрезает фото под эти пропорции перед загрузкой.
enum VideoFormat: String, CaseIterable, Codable, Sendable {
    case landscape = "16:9"
    case portrait = "9:16"
    case square = "1:1"

    /// Ширина, делённая на высоту.
    var aspectRatio: Double {
        switch self {
        case .landscape: 16.0 / 9.0
        case .portrait: 9.0 / 16.0
        case .square: 1
        }
    }
}
