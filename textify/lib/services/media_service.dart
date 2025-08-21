import 'package:file_picker/file_picker.dart';

class MediaService {
  /// Opens the file picker to select an image from the library.
  /// Returns a [PlatformFile] if an image is selected, or null if the user cancels.
  Future<PlatformFile?> pickImageFromLibrary() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      // Handle any exceptions (optional)
      print("Error picking image: $e");
      return null;
    }
  }
}
