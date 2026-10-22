import PhotosUI

extension PHPickerViewController {
    /// Пикер для одного фото. Сохраняет исходный формат, который `PhotoLoader` читает напрямую.
    static func makeSingleImagePicker(delegate: any PHPickerViewControllerDelegate) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = delegate
        return picker
    }
}
