/// Ячейка, которая показывает видео через `AutoplayController`.
@MainActor
protocol VideoPreviewProviding: AnyObject {
    var videoPreview: VideoPreviewView { get }
}
